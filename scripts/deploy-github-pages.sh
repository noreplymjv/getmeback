#!/usr/bin/env bash
# Redeploy GetMeBack to GitHub Pages (production). Portable.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

FLUTTER_BIN="${FLUTTER_BIN:-$(command -v flutter || true)}"
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
