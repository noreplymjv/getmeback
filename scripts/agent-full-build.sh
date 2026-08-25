#!/usr/bin/env bash
# Full GetMeBack build (analyze, test, Android, optional Linux). Portable.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ARTIFACTS="${GETMEBACK_ARTIFACTS:-$ROOT/dist/builds}"
BUILD_ROOT="${GETMEBACK_BUILD_ROOT:-$ROOT/dist/build-cache}"
SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$BUILD_ROOT/Android/Sdk}}"

FLUTTER_BIN="${FLUTTER_BIN:-$(command -v flutter || true)}"
JAVA_HOME="${JAVA_HOME:-${JAVA_HOME_FALLBACK:-}}"
if [ -z "${JAVA_HOME:-}" ] && command -v java >/dev/null 2>&1; then
  _java="$(command -v java)"
  JAVA_HOME="$(cd "$(dirname "$_java")/.." && pwd)"
fi

LOG="${GETMEBACK_BUILD_LOG:-/tmp/getmeback-full-build.log}"
exec > >(tee "$LOG") 2>&1

export HOME="${HOME:-$(eval echo "~$(id -un)")}"
export USER="${USER:-$(id -un)}"
export PATH="${FLUTTER_BIN:+$(dirname "$FLUTTER_BIN"):}${JAVA_HOME:+$JAVA_HOME/bin:}${HOME}/.local/bin:${SDK}/cmdline-tools/latest/bin:${SDK}/platform-tools:${PATH:-/usr/bin:/bin}"
export JAVA_HOME
export ANDROID_HOME="$SDK"
export ANDROID_SDK_ROOT="$SDK"
export PUB_CACHE="${PUB_CACHE:-$HOME/.pub-cache}"

mkdir -p "$ARTIFACTS" "$BUILD_ROOT"
cd "$ROOT"

echo "=== ENV ==="
whoami; id
echo "ROOT=$ROOT ARTIFACTS=$ARTIFACTS SDK=$SDK"
java -version || { echo JAVA missing; exit 1; }
if [ -z "$FLUTTER_BIN" ] || [ ! -x "$FLUTTER_BIN" ]; then
  echo "flutter not found; set FLUTTER_BIN or add flutter to PATH"
  exit 1
fi
"$FLUTTER_BIN" --version || true
df -h / "$ROOT" 2>/dev/null || df -h /

echo "=== LINUX DEPS ==="
LINUX_OK=0
if sudo -n true 2>/dev/null; then
  sudo -n "$ROOT/scripts/install-linux-deps.sh" && LINUX_OK=1 || LINUX_OK=0
else
  echo "sudo -n unavailable; skipping Linux deps install"
fi
if pkg-config --exists gtk+-3.0; then LINUX_OK=1; fi
echo "LINUX_OK=$LINUX_OK"

echo "=== SDK licenses + NDK/platform ==="
if command -v sdkmanager >/dev/null 2>&1; then
  yes | sdkmanager --licenses >/tmp/sdk-licenses.log 2>&1 || true
  sdkmanager --install "ndk;28.2.13676358" "cmake;3.22.1" "platform-tools" "platforms;android-36" "build-tools;36.0.0" 2>&1 | tail -40 || {
    echo "sdkmanager install failed; trying without specific NDK"
    sdkmanager --list 2>&1 | grep -i ndk | head -20 || true
  }
else
  echo "sdkmanager not on PATH; skipping SDK install (set ANDROID_HOME)"
fi

echo "=== flutter pub get ==="
run_flutter() {
  if [ "$(id -u)" = "0" ] && id "${SUDO_USER:-}" >/dev/null 2>&1; then
    local build_user="${SUDO_USER}"
    runuser -u "$build_user" -- env HOME="$(eval echo "~$build_user")" USER="$build_user" \
      PATH="$PATH" JAVA_HOME="$JAVA_HOME" \
      ANDROID_HOME="$ANDROID_HOME" ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" \
      PUB_CACHE="$PUB_CACHE" \
      bash -lc "cd '$ROOT' && flutter $*"
  elif [ "$(id -u)" = "0" ] && id mj >/dev/null 2>&1; then
    runuser -u mj -- env HOME="$(eval echo "~mj")" USER=mj \
      PATH="$PATH" JAVA_HOME="$JAVA_HOME" \
      ANDROID_HOME="$ANDROID_HOME" ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" \
      PUB_CACHE="$PUB_CACHE" \
      bash -lc "cd '$ROOT' && flutter $*"
  else
    flutter "$@"
  fi
}

run_flutter config --no-analytics || true
run_flutter pub get
echo "=== analyze ==="
run_flutter analyze
echo "=== test ==="
run_flutter test
echo "=== build apk debug ==="
run_flutter build apk --debug
echo "=== build apk release ==="
run_flutter build apk --release
echo "=== build appbundle ==="
run_flutter build appbundle --release

if [ "$LINUX_OK" = "1" ]; then
  echo "=== build linux ==="
  run_flutter build linux --release
  bash "$ROOT/scripts/package-linux.sh"
else
  echo "=== SKIP linux build (GTK/deps missing) ==="
fi

echo "=== copy artifacts ==="
mkdir -p "$ARTIFACTS"
DBG="$ROOT/build/app/outputs/flutter-apk/app-debug.apk"
REL="$ROOT/build/app/outputs/flutter-apk/app-release.apk"
AAB="$ROOT/build/app/outputs/bundle/release/app-release.aab"
cp -f "$DBG" "$ARTIFACTS/GetMeBack-debug.apk"
cp -f "$REL" "$ARTIFACTS/GetMeBack-release.apk"
cp -f "$AAB" "$ARTIFACTS/GetMeBack-release.aab"

if [ -f "$ROOT/dist/getmeback-linux-x64.tar.gz" ]; then
  cp -f "$ROOT/dist/getmeback-linux-x64.tar.gz" "$ARTIFACTS/GetMeBack-linux-x64.tar.gz"
  if [ -d "$ROOT/build/linux/x64/release/bundle" ]; then
    rsync -a "$ROOT/build/linux/x64/release/bundle/" "$ARTIFACTS/GetMeBack-linux-x64-bundle/"
  fi
fi

cat > "$ARTIFACTS/IPA-BUILD-NOTES.md" << 'EOF'
# IPA build (iOS)

Cannot produce an `.ipa` on Linux. GetMeBack iOS requires:

- macOS with Xcode
- Apple Developer account / signing
- From project: `flutter build ipa` (or open `ios/Runner.xcworkspace` in Xcode)

This Linux build session intentionally did **not** claim an IPA artifact.
EOF

echo "=== smoke ==="
file "$ARTIFACTS"/GetMeBack-*.apk "$ARTIFACTS"/GetMeBack-*.aab 2>/dev/null || true
ls -lh "$ARTIFACTS"
df -h / "$ROOT" 2>/dev/null || df -h /
echo FULL_BUILD_DONE
