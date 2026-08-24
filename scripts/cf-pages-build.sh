#!/usr/bin/env bash
# Cloudflare Pages build script — installs Flutter and builds the web app.
set -euo pipefail

FLUTTER_DIR="${FLUTTER_ROOT:-${HOME}/flutter}"
CHANNEL="${FLUTTER_CHANNEL:-stable}"

if [[ ! -x "${FLUTTER_DIR}/bin/flutter" ]]; then
  echo "Cloning Flutter (${CHANNEL})..."
  git clone https://github.com/flutter/flutter.git \
    --depth 1 -b "${CHANNEL}" "${FLUTTER_DIR}"
fi

export PATH="${FLUTTER_DIR}/bin:${PATH}"
flutter --version
flutter config --no-analytics --enable-web
flutter pub get
flutter build web --release --base-href /

# Cloudflare Pages serves SPA routes via _redirects / _headers from web/
cp -f web/_redirects build/web/_redirects 2>/dev/null || true
cp -f web/_headers build/web/_headers 2>/dev/null || true

echo "Build complete → build/web"
