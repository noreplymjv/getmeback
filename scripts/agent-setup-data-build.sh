#!/usr/bin/env bash
# Optionally relocate bulky Android/Gradle/pub caches under GETMEBACK_BUILD_ROOT.
# Defaults keep everything under the project tree (portable). Does not hardcode machine paths.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_ROOT="${GETMEBACK_BUILD_ROOT:-$ROOT/dist/build-cache}"
ARTIFACTS="${GETMEBACK_ARTIFACTS:-$ROOT/dist/builds}"
SDK_DEST="$BUILD_ROOT/Android/Sdk"
CACHE_ROOT="$BUILD_ROOT/caches"

FLUTTER_BIN="${FLUTTER_BIN:-$(command -v flutter || true)}"
FLUTTER_SDK="${FLUTTER_SDK:-}"
if [ -z "$FLUTTER_SDK" ] && [ -n "$FLUTTER_BIN" ]; then
  FLUTTER_SDK="$(cd "$(dirname "$FLUTTER_BIN")/.." && pwd)"
fi

HOME_DIR="${HOME:-$(eval echo "~$(id -un)")}"
ANDROID_SDK_LINK="${ANDROID_SDK_LINK:-$HOME_DIR/Android/Sdk}"
GRADLE_LINK="${GRADLE_USER_HOME:-$HOME_DIR/.gradle}"
PUB_LINK="${PUB_CACHE:-$HOME_DIR/.pub-cache}"

mkdir -p "$CACHE_ROOT" "$SDK_DEST" "$BUILD_ROOT/project-build" "$BUILD_ROOT/android-gradle" "$BUILD_ROOT/root-baks" "$ARTIFACTS"

link_or_move() {
  local src="$1"
  local dest="$2"
  local bak_name="$3"
  if [ -d "$src" ] && [ ! -L "$src" ]; then
    echo "Moving $src -> $dest ..."
    mkdir -p "$(dirname "$dest")"
    rsync -a "$src/" "$dest/"
    mv "$src" "$BUILD_ROOT/root-baks/${bak_name}.root-bak"
    ln -s "$dest" "$src"
  elif [ ! -e "$src" ]; then
    mkdir -p "$dest"
    mkdir -p "$(dirname "$src")"
    ln -s "$dest" "$src"
  fi
}

# Only relocate home caches when GETMEBACK_RELOCATE_HOME_CACHES=1 (opt-in).
if [ "${GETMEBACK_RELOCATE_HOME_CACHES:-0}" = "1" ]; then
  link_or_move "$ANDROID_SDK_LINK" "$SDK_DEST" "Sdk"
  link_or_move "$GRADLE_LINK" "$CACHE_ROOT/gradle" "gradle"
  link_or_move "$PUB_LINK" "$CACHE_ROOT/pub-cache" "pub-cache"
else
  echo "Skipping home-cache relocate (set GETMEBACK_RELOCATE_HOME_CACHES=1 to enable)."
  mkdir -p "$SDK_DEST" "$CACHE_ROOT/gradle" "$CACHE_ROOT/pub-cache"
fi

# Project build dirs always under BUILD_ROOT when requested
if [ "${GETMEBACK_RELOCATE_PROJECT_BUILD:-1}" = "1" ]; then
  link_or_move "$ROOT/build" "$BUILD_ROOT/project-build" "project-build"
  link_or_move "$ROOT/android/.gradle" "$BUILD_ROOT/android-gradle" "android-gradle"
fi

OWNER="${SUDO_USER:-$(id -un)}"
if id "$OWNER" >/dev/null 2>&1; then
  chown -R "$OWNER:$OWNER" "$BUILD_ROOT" "$ARTIFACTS" 2>/dev/null || true
fi

if [ -n "$FLUTTER_SDK" ]; then
  cat > "$ROOT/android/local.properties" <<EOF
flutter.sdk=$FLUTTER_SDK
sdk.dir=${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$SDK_DEST}}
EOF
  if id "$OWNER" >/dev/null 2>&1; then
    chown "$OWNER:$OWNER" "$ROOT/android/local.properties" 2>/dev/null || true
  fi
fi

echo "ROOT=$ROOT BUILD_ROOT=$BUILD_ROOT ARTIFACTS=$ARTIFACTS"
ls -la "$ROOT/build" "$ROOT/android/.gradle" 2>/dev/null || true
df -h / "$ROOT" 2>/dev/null || df -h /
du -sh "$SDK_DEST" "$CACHE_ROOT" 2>/dev/null || true
echo SETUP_DONE
