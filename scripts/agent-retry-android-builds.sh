#!/usr/bin/env bash
# Retry GetMeBack Android builds with fixed Flutter storage URL.
set -uo pipefail

PROJ=/home/mj/Projects/getmeback
SDK="/media/mj/DATA/iso files/getmeback-build/Android/Sdk"
ARTIFACTS="/media/mj/DATA/iso files/getmeback-builds"
LOG="$ARTIFACTS/build-retry-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$ARTIFACTS"

# Critical: empty/broken FLUTTER_STORAGE_BASE_URL becomes file:/download.flutter.io
unset FLUTTER_STORAGE_BASE_URL PUB_HOSTED_URL || true
export FLUTTER_STORAGE_BASE_URL=https://storage.googleapis.com
export PUB_HOSTED_URL=https://pub.dev

# Clear bad engine.realm (lone newline breaks storage URL)
: > /home/mj/flutter/bin/cache/engine.realm 2>/dev/null || true
printf '' > /home/mj/flutter/bin/cache/engine.realm 2>/dev/null || true

export CI=true
export HOME=/home/mj
export USER="${USER:-mj}"
export PATH="/home/mj/flutter/bin:/home/mj/.local/bin:$SDK/cmdline-tools/latest/bin:$SDK/platform-tools:/usr/bin:/bin"
export JAVA_HOME=/home/mj/.local/jdk
export ANDROID_HOME="$SDK"
export ANDROID_SDK_ROOT="$SDK"
export PUB_CACHE=/home/mj/.pub-cache
export GRADLE_USER_HOME=/home/mj/.gradle

# Ensure local.properties points at real SDK (space-safe)
cat > "$PROJ/android/local.properties" <<EOF
flutter.sdk=/home/mj/flutter
sdk.dir=$SDK
EOF

exec > >(tee -a "$LOG") 2>&1
echo "=== RETRY START $(date -Is) ==="
echo "FLUTTER_STORAGE_BASE_URL=$FLUTTER_STORAGE_BASE_URL"
whoami; id
df -h / /media/mj/DATA
xxd /home/mj/flutter/bin/cache/engine.realm | head -2 || true

run_as_build_user() {
  local cmd="$1"
  if [ "$(id -u)" = "0" ] && command -v runuser >/dev/null 2>&1; then
    if runuser -u mj -- true 2>/dev/null; then
      runuser -u mj -- env \
        CI=true HOME=/home/mj USER=mj LOGNAME=mj \
        FLUTTER_STORAGE_BASE_URL="$FLUTTER_STORAGE_BASE_URL" \
        PUB_HOSTED_URL="$PUB_HOSTED_URL" \
        PATH="$PATH" JAVA_HOME="$JAVA_HOME" \
        ANDROID_HOME="$ANDROID_HOME" ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" \
        PUB_CACHE="$PUB_CACHE" GRADLE_USER_HOME="$GRADLE_USER_HOME" \
        bash -lc "cd '$PROJ' && $cmd"
      return $?
    fi
  fi
  bash -lc "cd '$PROJ' && $cmd"
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
    (cd "$PROJ" && ./scripts/package-linux.sh) && PKG_RC=0 || PKG_RC=$?
  fi
else
  echo "=== LINUX SKIPPED (need: sudo ./scripts/install-linux-deps.sh) ==="
fi

echo "=== IPA ==="
ls -la "$PROJ/ios/ExportOptions.plist"
cat > "$ARTIFACTS/IPA-BUILD-NOTES.md" <<'EOF'
# IPA build (macOS only)

Cannot produce an `.ipa` on Linux.

On a Mac with Xcode + signing:
```bash
cd ~/Projects/getmeback
flutter build ipa
# or open ios/Runner.xcworkspace and Archive
# ExportOptions: ios/ExportOptions.plist
```
EOF

echo "=== COPY ARTIFACTS ==="
for src in \
  "$PROJ/build/app/outputs/flutter-apk/app-debug.apk" \
  "$PROJ/build/app/outputs/flutter-apk/app-release.apk" \
  "$PROJ/build/app/outputs/bundle/release/app-release.aab"
do
  if [ -f "$src" ]; then
    cp -av "$src" "$ARTIFACTS/"
  fi
done
find "$PROJ" -maxdepth 3 -name 'getmeback*.tar.gz' 2>/dev/null | while read -r t; do
  cp -av "$t" "$ARTIFACTS/" || true
done

echo "=== ARTIFACTS ==="
ls -lh "$PROJ/build/app/outputs/flutter-apk/"*.apk 2>/dev/null || echo 'no apks in project build'
ls -lh "$PROJ/build/app/outputs/bundle/release/"*.aab 2>/dev/null || echo 'no aab in project build'
ls -lh "$ARTIFACTS"
df -h / /media/mj/DATA
echo "SUMMARY DEBUG_RC=$DEBUG_RC RELEASE_RC=$RELEASE_RC AAB_RC=$AAB_RC LINUX_RC=$LINUX_RC PKG_RC=$PKG_RC GTK_OK=$GTK_OK"
echo "=== RETRY DONE $(date -Is) LOG=$LOG ==="
