#!/usr/bin/env bash
set -uo pipefail
export CI=true
export PATH="/home/mj/flutter/bin:/home/mj/.local/bin:$PATH"
export JAVA_HOME=/home/mj/.local/jdk
export ANDROID_HOME=/home/mj/Android/Sdk
export ANDROID_SDK_ROOT=/home/mj/Android/Sdk
export HOME=/home/mj
export PUB_CACHE=/home/mj/.pub-cache
export GRADLE_USER_HOME=/home/mj/.gradle
PROJ=/home/mj/Projects/getmeback
ARTIFACTS="/media/mj/DATA/iso files/getmeback-builds"
OVERFLOW="/media/mj/DATA/iso files/overflow-20260809"
LOG="$ARTIFACTS/build-log-$(date +%Y%m%d-%H%M%S).txt"
mkdir -p "$ARTIFACTS" "$OVERFLOW"
exec > >(tee -a "$LOG") 2>&1

echo "=== START $(date -Is) ==="
whoami; id
df -h / /media/mj/DATA

free_root() {
  local avail_kb
  avail_kb=$(df -Pk / | awk 'NR==2{print $4}')
  # ~2GB = 2097152 KB
  if [ "$avail_kb" -lt 2097152 ]; then
    echo "ROOT LOW (${avail_kb}KB). Moving bulky dirs..."
    for d in /home/mj/.cache/Google /home/mj/.cache/pip /tmp/flutter_* /home/mj/.local/share/Trash; do
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
    if sudo -n "$PROJ/scripts/install-linux-deps.sh"; then
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

# Prefer mj user for flutter
run_flutter() {
  if [ "$(id -u)" = "0" ] && id mj >/dev/null 2>&1; then
    runuser -u mj -- env CI=true HOME=/home/mj USER=mj LOGNAME=mj \
      PATH="$PATH" JAVA_HOME="$JAVA_HOME" ANDROID_HOME="$ANDROID_HOME" \
      ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" PUB_CACHE="$PUB_CACHE" \
      GRADLE_USER_HOME="$GRADLE_USER_HOME" \
      bash -lc "cd '$PROJ' && $*"
  else
    (cd "$PROJ" && eval "$*")
  fi
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
    (cd "$PROJ" && ./scripts/package-linux.sh)
    PKG_RC=$?
    echo PKG_RC=$PKG_RC
  fi
else
  echo "=== LINUX SKIPPED (GTK missing) ==="
fi

echo "=== IPA CHECK ==="
ls -la "$PROJ/ios/ExportOptions.plist" || true

echo "=== COPY ARTIFACTS ==="
for f in \
  "$PROJ/build/app/outputs/flutter-apk/app-debug.apk" \
  "$PROJ/build/app/outputs/flutter-apk/app-release.apk" \
  "$PROJ/build/app/outputs/bundle/release/app-release.aab" \
  "$PROJ"/build/linux/x64/release/*.tar.gz \
  "$PROJ"/*.tar.gz \
  "$PROJ"/dist/*.tar.gz
do
  if [ -f "$f" ]; then
    cp -av "$f" "$ARTIFACTS/" || true
  fi
done
# also find any linux package
find "$PROJ" -maxdepth 3 -name 'getmeback*.tar.gz' -o -name '*linux*.tar.gz' 2>/dev/null | while read -r t; do
  cp -av "$t" "$ARTIFACTS/" || true
done

echo "=== ARTIFACTS ==="
ls -lh \
  "$PROJ/build/app/outputs/flutter-apk/"*.apk 2>/dev/null || true
ls -lh \
  "$PROJ/build/app/outputs/bundle/release/"*.aab 2>/dev/null || true
ls -lh "$ARTIFACTS" 2>/dev/null || true
find "$PROJ/build/linux" -type f \( -name '*.tar.gz' -o -name 'getmeback' \) 2>/dev/null | head -20

echo "=== DISK ==="
df -h / /media/mj/DATA
echo "SUDO_STATUS=$SUDO_STATUS GTK_OK=$GTK_OK DEBUG_RC=$DEBUG_RC RELEASE_RC=$RELEASE_RC AAB_RC=$AAB_RC LINUX_RC=$LINUX_RC PKG_RC=$PKG_RC"
echo "=== DONE $(date -Is) LOG=$LOG ==="
