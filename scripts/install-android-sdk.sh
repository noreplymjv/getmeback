#!/usr/bin/env bash
# Install Android SDK command-line tools for GetMeBack (Flutter).
# Run once: ./scripts/install-android-sdk.sh

set -euo pipefail

SDK_ROOT="${ANDROID_HOME:-$HOME/Android/Sdk}"
JAVA_HOME="${JAVA_HOME:-$HOME/.local/jdk}"

export JAVA_HOME
export PATH="$JAVA_HOME/bin:$SDK_ROOT/cmdline-tools/latest/bin:$SDK_ROOT/platform-tools:$PATH"

mkdir -p "$SDK_ROOT/cmdline-tools"

if [ ! -d "$SDK_ROOT/cmdline-tools/latest" ]; then
  echo "Downloading Android command-line tools..."
  TMP=$(mktemp -d)
  curl -fsSL -o "$TMP/cmdline-tools.zip" \
    "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
  unzip -qo "$TMP/cmdline-tools.zip" -d "$SDK_ROOT/cmdline-tools"
  mv "$SDK_ROOT/cmdline-tools/cmdline-tools" "$SDK_ROOT/cmdline-tools/latest"
  rm -rf "$TMP"
fi

echo "Installing SDK packages (requires ~2 GB free disk)..."
yes | sdkmanager --sdk_root="$SDK_ROOT" \
  "platform-tools" \
  "platforms;android-35" \
  "build-tools;35.0.0"

echo "Configuring Flutter..."
flutter config --android-sdk "$SDK_ROOT"

echo "Done. Verify with: flutter doctor -v"
