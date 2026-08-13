#!/usr/bin/env bash
set -euo pipefail
exec > >(tee /tmp/getmeback-full-build.log) 2>&1

BUILD_ROOT="/media/mj/DATA/iso files/getmeback-build"
ARTIFACTS="/media/mj/DATA/iso files/getmeback-builds"
SDK="$BUILD_ROOT/Android/Sdk"
PROJ=/home/mj/Projects/getmeback

export HOME=/home/mj
export USER=mj
export PATH="/home/mj/flutter/bin:/home/mj/.local/bin:/home/mj/.local/jdk/bin:$SDK/cmdline-tools/latest/bin:$SDK/platform-tools:/usr/bin:/bin"
export JAVA_HOME=/home/mj/.local/jdk
export ANDROID_HOME="$SDK"
export ANDROID_SDK_ROOT="$SDK"
export PUB_CACHE=/home/mj/.pub-cache

cd "$PROJ"

echo "=== ENV ==="
whoami; id
java -version || { echo JAVA missing; exit 1; }
flutter --version || true
df -h / /media/mj/DATA

echo "=== LINUX DEPS ==="
LINUX_OK=0
if sudo -n true 2>/dev/null; then
  sudo -n "$PROJ/scripts/install-linux-deps.sh" && LINUX_OK=1 || LINUX_OK=0
else
  echo "sudo -n unavailable; skipping Linux deps install"
fi
if pkg-config --exists gtk+-3.0; then LINUX_OK=1; fi
echo "LINUX_OK=$LINUX_OK"

echo "=== SDK licenses + NDK/platform ==="
yes | sdkmanager --licenses >/tmp/sdk-licenses.log 2>&1 || true
# Install NDK matching Flutter (often 28.x) + cmake
sdkmanager --install "ndk;28.2.13676358" "cmake;3.22.1" "platform-tools" "platforms;android-36" "build-tools;36.0.0" 2>&1 | tail -40 || {
  echo "sdkmanager install failed; trying without specific NDK"
  sdkmanager --list 2>&1 | grep -i ndk | head -20 || true
}

echo "=== flutter pub get ==="
# Run as mj if we are root
run_flutter() {
  if [ "$(id -u)" = "0" ]; then
    runuser -u mj -- env HOME=/home/mj USER=mj \
      PATH="$PATH" JAVA_HOME="$JAVA_HOME" \
      ANDROID_HOME="$ANDROID_HOME" ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" \
      PUB_CACHE="$PUB_CACHE" \
      bash -lc "cd '$PROJ' && flutter $*"
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
  bash "$PROJ/scripts/package-linux.sh"
else
  echo "=== SKIP linux build (GTK/deps missing) ==="
fi

echo "=== copy artifacts ==="
mkdir -p "$ARTIFACTS"
# APK paths
DBG="$PROJ/build/app/outputs/flutter-apk/app-debug.apk"
REL="$PROJ/build/app/outputs/flutter-apk/app-release.apk"
AAB="$PROJ/build/app/outputs/bundle/release/app-release.aab"
cp -f "$DBG" "$ARTIFACTS/GetMeBack-debug.apk"
cp -f "$REL" "$ARTIFACTS/GetMeBack-release.apk"
cp -f "$AAB" "$ARTIFACTS/GetMeBack-release.aab"

if [ -f "$PROJ/dist/getmeback-linux-x64.tar.gz" ]; then
  cp -f "$PROJ/dist/getmeback-linux-x64.tar.gz" "$ARTIFACTS/GetMeBack-linux-x64.tar.gz"
  # also copy bundle dir as reference
  if [ -d "$PROJ/build/linux/x64/release/bundle" ]; then
    rsync -a "$PROJ/build/linux/x64/release/bundle/" "$ARTIFACTS/GetMeBack-linux-x64-bundle/"
  fi
fi

# IPA docs
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
df -h / /media/mj/DATA
echo FULL_BUILD_DONE
