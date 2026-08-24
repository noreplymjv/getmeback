#!/usr/bin/env bash
# Cloudflare Workers/Pages build — installs Flutter and builds the web app.
set -euo pipefail

echo "== GetMeBack Cloudflare build =="
echo "pwd=$(pwd)"
echo "node=$(node -v 2>/dev/null || echo n/a)"

FLUTTER_DIR="${FLUTTER_ROOT:-${HOME}/flutter}"
CHANNEL="${FLUTTER_CHANNEL:-stable}"

if [[ ! -x "${FLUTTER_DIR}/bin/flutter" ]]; then
  echo "Cloning Flutter (${CHANNEL}) into ${FLUTTER_DIR}..."
  rm -rf "${FLUTTER_DIR}"
  git clone https://github.com/flutter/flutter.git \
    --depth 1 -b "${CHANNEL}" "${FLUTTER_DIR}"
fi

export PATH="${FLUTTER_DIR}/bin:${PATH}"
export PUB_CACHE="${PUB_CACHE:-${HOME}/.pub-cache}"

flutter --version
flutter config --no-analytics --enable-web
flutter pub get
flutter build web --release --base-href /

# Copy Cloudflare routing / headers into the built site
cp -f web/_redirects build/web/_redirects 2>/dev/null || true
cp -f web/_headers build/web/_headers 2>/dev/null || true

# Sanity check: real Flutter build has more than a handful of files
COUNT=$(find build/web -type f | wc -l | tr -d ' ')
echo "Built file count: ${COUNT}"
if [[ "${COUNT}" -lt 20 ]]; then
  echo "ERROR: build/web looks incomplete (${COUNT} files). Aborting."
  ls -la build/web || true
  exit 1
fi

echo "Build complete → build/web ($(du -sh build/web | cut -f1))"
