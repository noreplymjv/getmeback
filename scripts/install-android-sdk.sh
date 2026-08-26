#!/usr/bin/env bash
# Install Android SDK command-line tools for GetMeBack (Flutter).
# Run once: ./scripts/install-android-sdk.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"


# Prefer env, then AllProjects/.portable-sdk, then app/.tooling, then PATH
_resolve_flutter() {
  if [ -n "${FLUTTER_BIN:-}" ] && [ -x "${FLUTTER_BIN}" ]; then
    echo "$FLUTTER_BIN"; return
  fi
  local c
  for c in \
    "$ROOT/../../.portable-sdk/flutter/bin/flutter" \
    "$ROOT/../.portable-sdk/flutter/bin/flutter" \
    "$ROOT/.tooling/flutter/bin/flutter"
  do
    if [ -x "$c" ]; then echo "$c"; return; fi
  done
  command -v flutter 2>/dev/null || true
}

_resolve_java_home() {
  if [ -n "${JAVA_HOME:-}" ] && [ -x "${JAVA_HOME}/bin/java" ]; then
    echo "$JAVA_HOME"; return
  fi
  local c
  for c in \
    "$ROOT/../../.portable-sdk/jdk" \
    "$ROOT/../.portable-sdk/jdk" \
    "$ROOT/.tooling/jdk" \
    "${HOME}/.local/jdk"
  do
    if [ -x "$c/bin/java" ]; then echo "$c"; return; fi
  done
  if command -v java >/dev/null 2>&1; then
    _java="$(command -v java)"
    (cd "$(dirname "$_java")/.." && pwd)
    return
  fi
  echo ""
}

_resolve_android_home() {
  if [ -n "${ANDROID_HOME:-}" ] && [ -d "${ANDROID_HOME}" ]; then
    echo "$ANDROID_HOME"; return
  fi
  if [ -n "${ANDROID_SDK_ROOT:-}" ] && [ -d "${ANDROID_SDK_ROOT}" ]; then
    echo "$ANDROID_SDK_ROOT"; return
  fi
  local c
  for c in \
    "$ROOT/../../.portable-sdk/android-sdk" \
    "$ROOT/../.portable-sdk/android-sdk" \
    "$ROOT/../android-sdk" \
    "$ROOT/.tooling/android-sdk"
  do
    if [ -d "$c" ]; then echo "$c"; return; fi
  done
  echo ""
}


_PORTABLE_SDK="$(_resolve_android_home)"
SDK_ROOT="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-${_PORTABLE_SDK:-$HOME/Android/Sdk}}}"
if [ -z "${JAVA_HOME:-}" ]; then
  JAVA_HOME="$(_resolve_java_home)"
fi

export JAVA_HOME
export PATH="${JAVA_HOME:+$JAVA_HOME/bin:}$SDK_ROOT/cmdline-tools/latest/bin:$SDK_ROOT/platform-tools:$PATH"
echo "ROOT=$ROOT SDK_ROOT=$SDK_ROOT"

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
