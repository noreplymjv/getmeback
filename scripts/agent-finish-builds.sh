#!/usr/bin/env bash
# Finish remaining GetMeBack builds and collect artifacts. Portable.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ARTIFACTS="${GETMEBACK_ARTIFACTS:-$ROOT/dist/builds}"
OVERFLOW="${GETMEBACK_OVERFLOW:-$ROOT/dist/overflow}"

FLUTTER_BIN="${FLUTTER_BIN:-$(command -v flutter || true)}"
JAVA_HOME="${JAVA_HOME:-}"
if [ -z "${JAVA_HOME:-}" ] && command -v java >/dev/null 2>&1; then
  _java="$(command -v java)"
  JAVA_HOME="$(cd "$(dirname "$_java")/.." && pwd)"
fi

SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"

export CI=true
export HOME="${HOME:-$(eval echo "~$(id -un)")}"
export PATH="${FLUTTER_BIN:+$(dirname "$FLUTTER_BIN"):}${JAVA_HOME:+$JAVA_HOME/bin:}${HOME}/.local/bin:${SDK:+$SDK/cmdline-tools/latest/bin:$SDK/platform-tools:}${PATH:-}"
export JAVA_HOME
if [ -n "$SDK" ]; then
  export ANDROID_HOME="$SDK"
  export ANDROID_SDK_ROOT="$SDK"
fi
export PUB_CACHE="${PUB_CACHE:-$HOME/.pub-cache}"
export GRADLE_USER_HOME="${GRADLE_USER_HOME:-$HOME/.gradle}"

LOG="$ARTIFACTS/build-log-$(date +%Y%m%d-%H%M%S).txt"
mkdir -p "$ARTIFACTS" "$OVERFLOW"
exec > >(tee -a "$LOG") 2>&1

echo "=== START $(date -Is) ==="
echo "ROOT=$ROOT ARTIFACTS=$ARTIFACTS"
whoami; id
df -h / "$ROOT" 2>/dev/null || df -h /

free_root() {
  local avail_kb
  avail_kb=$(df -Pk / | awk 'NR==2{print $4}')
  # ~2GB = 2097152 KB
  if [ "$avail_kb" -lt 2097152 ]; then
    echo "ROOT LOW (${avail_kb}KB). Moving bulky dirs under OVERFLOW..."
    for d in "$HOME/.cache/Google" "$HOME/.cache/pip" /tmp/flutter_* "$HOME/.local/share/Trash"; do
      if [ -e "$d" ]; then
        base=$(basename "$d")
        dest="$OVERFLOW/${base}-$(date +%H%M%S)"
        mv "$d" "$dest" && echo "moved $d -> $dest" || true
      fi
    done
  fi
  df -h /
}

# 1) Linux deps
echo "=== LINUX DEPS ==="
SUDO_STATUS="unknown"
if apt-get update; then
  if DEBIAN_FRONTEND=noninteractive apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev libblkid-dev liblzma-dev libstdc++-12-dev; then
    SUDO_STATUS="apt_as_root_ok"
    echo GTK_INSTALLED
  else
    SUDO_STATUS="apt_install_failed"
  fi
else
  if sudo -n true 2>/dev/null; then
    if sudo -n "$ROOT/scripts/install-linux-deps.sh"; then
      SUDO_STATUS="sudo_nopass_ok"
    else
      SUDO_STATUS="sudo_nopass_script_failed"
    fi
  else
    SUDO_STATUS="sudo_needs_password_or_broken"
  fi
fi
pkg-config --exists gtk+-3.0 && GTK_OK=1 || GTK_OK=0
echo "SUDO_STATUS=$SUDO_STATUS GTK_OK=$GTK_OK"

run_flutter() {
  if [ "$(id -u)" = "0" ]; then
    local build_user="${SUDO_USER:-}"
    if [ -z "$build_user" ] && id mj >/dev/null 2>&1; then
      build_user=mj
    fi
    if [ -n "$build_user" ] && id "$build_user" >/dev/null 2>&1; then
      runuser -u "$build_user" -- env CI=true HOME="$(eval echo "~$build_user")" USER="$build_user" LOGNAME="$build_user" \
        PATH="$PATH" JAVA_HOME="$JAVA_HOME" ANDROID_HOME="${ANDROID_HOME:-}" \
        ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-}" PUB_CACHE="$PUB_CACHE" \
        GRADLE_USER_HOME="$GRADLE_USER_HOME" \
        bash -lc "cd '$ROOT' && $*"
      return $?
    fi
  fi
  (cd "$ROOT" && eval "$*")
}

echo "=== FLUTTER DOCTOR ==="
run_flutter 'flutter doctor -v' || true
free_root

echo "=== PUB GET ==="
run_flutter 'flutter pub get' || true

echo "=== DEBUG APK ==="
free_root
run_flutter 'flutter build apk --debug'
DEBUG_RC=$?
echo DEBUG_RC=$DEBUG_RC

echo "=== RELEASE APK ==="
free_root
run_flutter 'flutter build apk --release'
RELEASE_RC=$?
echo RELEASE_RC=$RELEASE_RC

echo "=== APP BUNDLE ==="
free_root
run_flutter 'flutter build appbundle --release'
AAB_RC=$?
echo AAB_RC=$AAB_RC

LINUX_RC=skip
PKG_RC=skip
if [ "$GTK_OK" = "1" ]; then
  echo "=== LINUX RELEASE ==="
  free_root
  run_flutter 'flutter build linux --release'
  LINUX_RC=$?
  echo LINUX_RC=$LINUX_RC
  if [ "$LINUX_RC" = "0" ]; then
    (cd "$ROOT" && ./scripts/package-linux.sh)
    PKG_RC=$?
    echo PKG_RC=$PKG_RC
  fi
else
  echo "=== LINUX SKIPPED (GTK missing) ==="
fi

echo "=== IPA CHECK ==="
ls -la "$ROOT/ios/ExportOptions.plist" || true

echo "=== COPY ARTIFACTS ==="
for f in \
  "$ROOT/build/app/outputs/flutter-apk/app-debug.apk" \
  "$ROOT/build/app/outputs/flutter-apk/app-release.apk" \
  "$ROOT/build/app/outputs/bundle/release/app-release.aab" \
  "$ROOT"/build/linux/x64/release/*.tar.gz \
  "$ROOT"/*.tar.gz \
  "$ROOT"/dist/*.tar.gz
do
  if [ -f "$f" ]; then
    cp -av "$f" "$ARTIFACTS/" || true
  fi
done
find "$ROOT" -maxdepth 3 \( -name 'getmeback*.tar.gz' -o -name '*linux*.tar.gz' \) 2>/dev/null | while read -r t; do
  cp -av "$t" "$ARTIFACTS/" || true
done

echo "=== ARTIFACTS ==="
ls -lh \
  "$ROOT/build/app/outputs/flutter-apk/"*.apk 2>/dev/null || true
ls -lh \
  "$ROOT/build/app/outputs/bundle/release/"*.aab 2>/dev/null || true
ls -lh "$ARTIFACTS" 2>/dev/null || true
find "$ROOT/build/linux" -type f \( -name '*.tar.gz' -o -name 'getmeback' \) 2>/dev/null | head -20

echo "=== DISK ==="
df -h / "$ROOT" 2>/dev/null || df -h /
echo "SUDO_STATUS=$SUDO_STATUS GTK_OK=$GTK_OK DEBUG_RC=$DEBUG_RC RELEASE_RC=$RELEASE_RC AAB_RC=$AAB_RC LINUX_RC=$LINUX_RC PKG_RC=$PKG_RC"
echo "=== DONE $(date -Is) LOG=$LOG ==="
