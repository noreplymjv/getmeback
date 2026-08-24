#!/usr/bin/env bash
# Cloudflare CI: verify prebuilt Flutter site exists (no Flutter install needed).
set -euo pipefail
DIR="cf-dist"
if [[ ! -d "$DIR" ]]; then
  echo "ERROR: $DIR missing. Run locally: flutter build web && cp -a build/web cf-dist"
  exit 1
fi
COUNT=$(find "$DIR" -type f | wc -l | tr -d ' ')
echo "cf-dist file count: $COUNT"
if [[ "$COUNT" -lt 20 ]]; then
  echo "ERROR: $DIR looks incomplete."
  exit 1
fi
test -f "$DIR/index.html"
test -f "$DIR/flutter_bootstrap.js" -o -f "$DIR/main.dart.js" -o -f "$DIR/flutter.js"
echo "Prebuilt site OK — Cloudflare will upload $DIR"
