#!/usr/bin/env bash
set -euo pipefail
BUILD_ROOT="/media/mj/DATA/iso files/getmeback-build"
ARTIFACTS="/media/mj/DATA/iso files/getmeback-builds"
SDK_DEST="$BUILD_ROOT/Android/Sdk"
CACHE_ROOT="$BUILD_ROOT/caches"
PROJ=/home/mj/Projects/getmeback

mkdir -p "$CACHE_ROOT" "$SDK_DEST" "$BUILD_ROOT/project-build" "$BUILD_ROOT/android-gradle" "$BUILD_ROOT/root-baks" "$ARTIFACTS"

if [ -d /home/mj/Android/Sdk ] && [ ! -L /home/mj/Android/Sdk ]; then
  echo "Moving Android SDK to DATA..."
  rsync -a /home/mj/Android/Sdk/ "$SDK_DEST/"
  mv /home/mj/Android/Sdk "$BUILD_ROOT/root-baks/Sdk.root-bak"
  ln -s "$SDK_DEST" /home/mj/Android/Sdk
elif [ ! -e /home/mj/Android/Sdk ]; then
  ln -s "$SDK_DEST" /home/mj/Android/Sdk
fi

if [ -d /home/mj/.gradle ] && [ ! -L /home/mj/.gradle ]; then
  echo "Moving .gradle to DATA..."
  rsync -a /home/mj/.gradle/ "$CACHE_ROOT/gradle/"
  mv /home/mj/.gradle "$BUILD_ROOT/root-baks/gradle.root-bak"
  ln -s "$CACHE_ROOT/gradle" /home/mj/.gradle
elif [ ! -e /home/mj/.gradle ]; then
  mkdir -p "$CACHE_ROOT/gradle"
  ln -s "$CACHE_ROOT/gradle" /home/mj/.gradle
fi

if [ -d /home/mj/.pub-cache ] && [ ! -L /home/mj/.pub-cache ]; then
  echo "Moving pub-cache to DATA..."
  rsync -a /home/mj/.pub-cache/ "$CACHE_ROOT/pub-cache/"
  mv /home/mj/.pub-cache "$BUILD_ROOT/root-baks/pub-cache.root-bak"
  ln -s "$CACHE_ROOT/pub-cache" /home/mj/.pub-cache
elif [ ! -e /home/mj/.pub-cache ]; then
  mkdir -p "$CACHE_ROOT/pub-cache"
  ln -s "$CACHE_ROOT/pub-cache" /home/mj/.pub-cache
fi

if [ -d "$PROJ/build" ] && [ ! -L "$PROJ/build" ]; then
  echo "Moving project build/ to DATA..."
  rsync -a "$PROJ/build/" "$BUILD_ROOT/project-build/"
  mv "$PROJ/build" "$BUILD_ROOT/root-baks/project-build.root-bak"
  ln -s "$BUILD_ROOT/project-build" "$PROJ/build"
elif [ ! -e "$PROJ/build" ]; then
  mkdir -p "$BUILD_ROOT/project-build"
  ln -s "$BUILD_ROOT/project-build" "$PROJ/build"
fi

if [ -d "$PROJ/android/.gradle" ] && [ ! -L "$PROJ/android/.gradle" ]; then
  rsync -a "$PROJ/android/.gradle/" "$BUILD_ROOT/android-gradle/"
  mv "$PROJ/android/.gradle" "$BUILD_ROOT/root-baks/android-gradle.root-bak"
  ln -s "$BUILD_ROOT/android-gradle" "$PROJ/android/.gradle"
elif [ ! -e "$PROJ/android/.gradle" ]; then
  mkdir -p "$BUILD_ROOT/android-gradle"
  ln -s "$BUILD_ROOT/android-gradle" "$PROJ/android/.gradle"
fi

chown -R mj:mj "$BUILD_ROOT" "$ARTIFACTS" || true
chown -h mj:mj /home/mj/Android/Sdk /home/mj/.gradle /home/mj/.pub-cache "$PROJ/build" "$PROJ/android/.gradle" || true

cat > "$PROJ/android/local.properties" <<EOF
flutter.sdk=/home/mj/flutter
sdk.dir=$SDK_DEST
EOF
chown mj:mj "$PROJ/android/local.properties"

ls -la /home/mj/Android/Sdk /home/mj/.gradle /home/mj/.pub-cache "$PROJ/build" "$PROJ/android/.gradle"
df -h / /media/mj/DATA
du -sh "$SDK_DEST" "$CACHE_ROOT" 2>/dev/null || true
echo SETUP_DONE
