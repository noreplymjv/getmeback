#!/usr/bin/env bash
# Retry GetMeBack Android builds with fixed Flutter storage URL. Portable.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ARTIFACTS="${GETMEBACK_ARTIFACTS:-$ROOT/dist/builds}"
BUILD_ROOT="${GETMEBACK_BUILD_ROOT:-$ROOT/dist/build-cache}"
SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$BUILD_ROOT/Android/Sdk}}"

FLUTTER_BIN="${FLUTTER_BIN:-$(command -v flutter || true)}"
FLUTTER_SDK="${FLUTTER_SDK:-}"
if [ -z "$FLUTTER_SDK" ] && [ -n "$FLUTTER_BIN" ]; then
  FLUTTER_SDK="$(cd "$(dirname "$FLUTTER_BIN")/.." && pwd)"
fi

JAVA_HOME="${JAVA_HOME:-}"
if [ -z "${JAVA_HOME:-}" ] && command -v java >/dev/null 2>&1; then
  _java="$(command -v java)"
  JAVA_HOME="$(cd "$(dirname "$_java")/.." && pwd)"
fi

LOG="$ARTIFACTS/build-retry-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$ARTIFACTS"

# Critical: empty/broken FLUTTER_STORAGE_BASE_URL becomes file:/download.flutter.io
unset FLUTTER_STORAGE_BASE_URL PUB_HOSTED_URL || true
export FLUTTER_STORAGE_BASE_URL=https://storage.googleapis.com
export PUB_HOSTED_URL=https://pub.dev

# Clear bad engine.realm (lone newline breaks storage URL) if Flutter SDK known
if [ -n "$FLUTTER_SDK" ] && [ -d "$FLUTTER_SDK/bin/cache" ]; then
  : > "$FLUTTER_SDK/bin/cache/engine.realm" 2>/dev/null || true
  printf '' > "$FLUTTER_SDK/bin/cache/engine.realm" 2>/dev/null || true
fi

export CI=true
export HOME="${HOME:-$(eval echo "~$(id -un)")}"
export USER="${USER:-$(id -un)}"
export PATH="${FLUTTER_BIN:+$(dirname "$FLUTTER_BIN"):}${HOME}/.local/bin:${SDK}/cmdline-tools/latest/bin:${SDK}/platform-tools:${PATH:-/usr/bin:/bin}"
export JAVA_HOME
export ANDROID_HOME="$SDK"
export ANDROID_SDK_ROOT="$SDK"
export PUB_CACHE="${PUB_CACHE:-$HOME/.pub-cache}"
export GRADLE_USER_HOME="${GRADLE_USER_HOME:-$HOME/.gradle}"

# Ensure local.properties points at discovered SDK (space-safe)
if [ -n "$FLUTTER_SDK" ]; then
  cat > "$ROOT/android/local.properties" <<EOF
flutter.sdk=$FLUTTER_SDK
sdk.dir=$SDK
EOF
fi

exec > >(tee -a "$LOG") 2>&1
echo "=== RETRY START $(date -Is) ==="
echo "ROOT=$ROOT ARTIFACTS=$ARTIFACTS SDK=$SDK FLUTTER_SDK=$FLUTTER_SDK"
echo "FLUTTER_STORAGE_BASE_URL=$FLUTTER_STORAGE_BASE_URL"
whoami; id
df -h / "$ROOT" 2>/dev/null || df -h /
if [ -n "$FLUTTER_SDK" ] && [ -f "$FLUTTER_SDK/bin/cache/engine.realm" ]; then
  xxd "$FLUTTER_SDK/bin/cache/engine.realm" | head -2 || true
fi

run_as_build_user() {
  local cmd="$1"
  if [ "$(id -u)" = "0" ] && command -v runuser >/dev/null 2>&1; then
    local build_user="${SUDO_USER:-}"
    if [ -z "$build_user" ] && id mj >/dev/null 2>&1; then
      build_user=mj
    fi
    if [ -n "$build_user" ] && runuser -u "$build_user" -- true 2>/dev/null; then
      runuser -u "$build_user" -- env \
        CI=true HOME="$(eval echo "~$build_user")" USER="$build_user" LOGNAME="$build_user" \
        FLUTTER_STORAGE_BASE_URL="$FLUTTER_STORAGE_BASE_URL" \
        PUB_HOSTED_URL="$PUB_HOSTED_URL" \
        PATH="$PATH" JAVA_HOME="$JAVA_HOME" \
        ANDROID_HOME="$ANDROID_HOME" ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" \
        PUB_CACHE="$PUB_CACHE" GRADLE_USER_HOME="$GRADLE_USER_HOME" \
        bash -lc "cd '$ROOT' && $cmd"
      return $?
    fi
  fi
  bash -lc "cd '$ROOT' && $cmd"
}

echo "=== flutter doctor ==="
run_as_build_user 'flutter doctor -v' || true

echo "=== pub get ==="
run_as_build_user 'flutter pub get'

echo "=== DEBUG APK ==="
run_as_build_user 'flutter build apk --debug'
DEBUG_RC=$?
echo DEBUG_RC=$DEBUG_RC

echo "=== RELEASE APK ==="
run_as_build_user 'flutter build apk --release'
RELEASE_RC=$?
echo RELEASE_RC=$RELEASE_RC

echo "=== APP BUNDLE ==="
run_as_build_user 'flutter build appbundle --release'
AAB_RC=$?
echo AAB_RC=$AAB_RC

GTK_OK=0
pkg-config --exists gtk+-3.0 && GTK_OK=1 || true
LINUX_RC=skip
PKG_RC=skip
if [ "$GTK_OK" = "1" ]; then
  echo "=== LINUX ==="
  run_as_build_user 'flutter build linux --release'
  LINUX_RC=$?
  if [ "$LINUX_RC" = "0" ]; then
    (cd "$ROOT" && ./scripts/package-linux.sh) && PKG_RC=0 || PKG_RC=$?
  fi
else
  echo "=== LINUX SKIPPED (need: sudo ./scripts/install-linux-deps.sh) ==="
fi

echo "=== IPA ==="
ls -la "$ROOT/ios/ExportOptions.plist" 2>/dev/null || true
cat > "$ARTIFACTS/IPA-BUILD-NOTES.md" <<'EOF'
# IPA build (macOS only)

Cannot produce an `.ipa` on Linux.

On a Mac with Xcode + signing:
```bash
# from project root
flutter build ipa
# or open ios/Runner.xcworkspace and Archive
# ExportOptions: ios/ExportOptions.plist
```
EOF

echo "=== COPY ARTIFACTS ==="
for src in \
  "$ROOT/build/app/outputs/flutter-apk/app-debug.apk" \
  "$ROOT/build/app/outputs/flutter-apk/app-release.apk" \
  "$ROOT/build/app/outputs/bundle/release/app-release.aab"
do
  if [ -f "$src" ]; then
    cp -av "$src" "$ARTIFACTS/"
  fi
done
find "$ROOT" -maxdepth 3 -name 'getmeback*.tar.gz' 2>/dev/null | while read -r t; do
  cp -av "$t" "$ARTIFACTS/" || true
done

echo "=== ARTIFACTS ==="
ls -lh "$ROOT/build/app/outputs/flutter-apk/"*.apk 2>/dev/null || echo 'no apks in project build'
ls -lh "$ROOT/build/app/outputs/bundle/release/"*.aab 2>/dev/null || echo 'no aab in project build'
ls -lh "$ARTIFACTS"
df -h / "$ROOT" 2>/dev/null || df -h /
echo "SUMMARY DEBUG_RC=$DEBUG_RC RELEASE_RC=$RELEASE_RC AAB_RC=$AAB_RC LINUX_RC=$LINUX_RC PKG_RC=$PKG_RC GTK_OK=$GTK_OK"
echo "=== RETRY DONE $(date -Is) LOG=$LOG ==="
