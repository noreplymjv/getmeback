#!/usr/bin/env bash
# Redeploy GetMeBack to GitHub Pages (production).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
FLUTTER_BIN="${FLUTTER_BIN:-/home/mj/flutter/bin/flutter}"
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
