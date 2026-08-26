#!/usr/bin/env bash
# Redeploy GetMeBack to GitHub Pages (production). Portable.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"


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
    "$HOME/.local/jdk"
  do
    if [ -x "$c/bin/java" ]; then echo "$c"; return; fi
  done
  if command -v java >/dev/null 2>&1; then
    _java="$(command -v java)"
    cd "$(dirname "$_java")/.." && pwd
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

FLUTTER_BIN="$(_resolve_flutter)"
if [ -z "$FLUTTER_BIN" ] || [ ! -x "$FLUTTER_BIN" ]; then
  echo "flutter not found; set FLUTTER_BIN or add flutter to PATH" >&2
  exit 1
fi

"$FLUTTER_BIN" build web --release --base-href /getmeback/ --no-wasm-dry-run
TMP="$(mktemp -d /tmp/getmeback-ghpages.XXXXXX)"
cp -a build/web/. "$TMP"/
cp -f "$TMP/index.html" "$TMP/404.html"
touch "$TMP/.nojekyll"
cd "$TMP"
git init -b gh-pages
git add -A
GIT_AUTHOR_NAME='Mj' GIT_AUTHOR_EMAIL='mj@local' GIT_COMMITTER_NAME='Mj' GIT_COMMITTER_EMAIL='mj@local' \
  git commit -m "Deploy GetMeBack web $(date -u +%Y-%m-%dT%H:%MZ)"
git remote add origin https://github.com/noreplymjv/getmeback.git
git push -f origin gh-pages
echo "Live: https://noreplymjv.github.io/getmeback/"
