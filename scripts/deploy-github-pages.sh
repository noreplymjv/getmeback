#!/usr/bin/env bash
# Deploy GetMeBack web to GitHub Pages.
#
# Usage:
#   ./scripts/deploy-github-pages.sh              # replace site ROOT (keeps version folders like v2/)
#   ./scripts/deploy-github-pages.sh v2           # deploy ONLY into /getmeback/v2/ (root stays)
#   ./scripts/deploy-github-pages.sh --root       # same as no args (root)
#
# Live:
#   https://noreplymjv.github.io/getmeback/       (stable / current root)
#   https://noreplymjv.github.io/getmeback/v2/    (versioned)
#   https://noreplymjv.github.io/getmeback/versions.html
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

REPO_URL="${GETMEBACK_GIT_REMOTE:-https://github.com/noreplymjv/getmeback.git}"
SITE_NAME="getmeback"

TARGET="${1:-}"
if [ "$TARGET" = "--root" ] || [ "$TARGET" = "root" ] || [ -z "$TARGET" ]; then
  SLOT=""
elif [[ "$TARGET" =~ ^[a-zA-Z0-9._-]+$ ]]; then
  SLOT="$TARGET"
else
  echo "Invalid version slot: $TARGET (use letters/numbers only, e.g. v2)" >&2
  exit 1
fi

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

FLUTTER_BIN="$(_resolve_flutter)"
if [ -z "$FLUTTER_BIN" ] || [ ! -x "$FLUTTER_BIN" ]; then
  echo "flutter not found; set FLUTTER_BIN or add flutter to PATH" >&2
  exit 1
fi

if [ -n "$SLOT" ]; then
  BASE_HREF="/${SITE_NAME}/${SLOT}/"
  LIVE_URL="https://noreplymjv.github.io/${SITE_NAME}/${SLOT}/"
else
  BASE_HREF="/${SITE_NAME}/"
  LIVE_URL="https://noreplymjv.github.io/${SITE_NAME}/"
fi

echo "Building web (base-href ${BASE_HREF})..."
"$FLUTTER_BIN" build web --release --base-href "$BASE_HREF" --no-wasm-dry-run

TMP="$(mktemp -d /tmp/getmeback-ghpages.XXXXXX)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

echo "Fetching existing gh-pages (preserve other versions)..."
git clone --depth 1 --branch gh-pages "$REPO_URL" "$TMP/site" 2>/dev/null \
  || {
    echo "No gh-pages yet — initializing empty site tree."
    mkdir -p "$TMP/site"
    git -C "$TMP/site" init -b gh-pages
    git -C "$TMP/site" remote add origin "$REPO_URL"
  }

# Drop nested .git from clone when we re-commit whole tree? Keep it and commit in place.
SITE="$TMP/site"

write_versions_index() {
  local out="$SITE/versions.html"
  cat >"$out" <<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>GetMeBack — live versions</title>
  <style>
    body{font-family:system-ui,sans-serif;max-width:40rem;margin:3rem auto;padding:0 1.25rem;
      background:#12141a;color:#f2f2f2;line-height:1.5}
    a{color:#7dd3c0;font-weight:700}
    .card{border:1px solid #333;border-radius:12px;padding:1rem 1.2rem;margin:1rem 0;background:#1a1d26}
    h1{font-size:1.5rem;margin:0 0 .5rem}
    p{color:#b8bcc8}
  </style>
</head>
<body>
  <h1>GetMeBack — live versions</h1>
  <p>All builds stay online simultaneously. Pick a version:</p>
  <div class="card">
    <div><strong>Version 3 (World-Class Next-Gen)</strong> — Voronoi Shatter, Optical Shockwaves, Kinetic Swipes & Kintsugi</div>
    <a href="./v3/">https://noreplymjv.github.io/getmeback/v3/</a>
  </div>
  <div class="card">
    <div><strong>Version 2 (Realistic Demolition)</strong> — Multi-stage prop destruction & arsenal HUD</div>
    <a href="./v2/">https://noreplymjv.github.io/getmeback/v2/</a>
  </div>
  <div class="card">
    <div><strong>Stable (v1 Root)</strong></div>
    <a href="./">https://noreplymjv.github.io/getmeback/</a>
  </div>
</body>
</html>
HTML
}

if [ -n "$SLOT" ]; then
  echo "Deploying into slot /${SLOT}/ (root untouched)..."
  rm -rf "$SITE/$SLOT"
  mkdir -p "$SITE/$SLOT"
  cp -a build/web/. "$SITE/$SLOT"/
  cp -f "$SITE/$SLOT/index.html" "$SITE/$SLOT/404.html"
else
  echo "Deploying to site root (preserving version folders)..."
  # Remove root app files but keep version directories + versions.html
  find "$SITE" -mindepth 1 -maxdepth 1 ! -name '.git' ! -name 'v*' ! -name 'versions.html' -exec rm -rf {} +
  cp -a build/web/. "$SITE"/
  cp -f "$SITE/index.html" "$SITE/404.html"
fi

touch "$SITE/.nojekyll"
write_versions_index

cd "$SITE"
git add -A
if git diff --cached --quiet; then
  echo "No file changes to publish."
else
  GIT_AUTHOR_NAME='Mj' GIT_AUTHOR_EMAIL='mj@local' \
  GIT_COMMITTER_NAME='Mj' GIT_COMMITTER_EMAIL='mj@local' \
    git commit -m "Deploy GetMeBack web ${SLOT:-root} $(date -u +%Y-%m-%dT%H:%MZ)"
  # Prefer non-force if history allows; force only when needed for orphan/shallow.
  if ! git push origin HEAD:gh-pages 2>/tmp/gmb-gh-push.err; then
    echo "Normal push failed; force-pushing gh-pages (keeps multi-version tree in this commit)..."
    cat /tmp/gmb-gh-push.err >&2 || true
    git push -f origin HEAD:gh-pages
  fi
fi

echo ""
echo "Live this deploy: $LIVE_URL"
echo "Versions index:   https://noreplymjv.github.io/${SITE_NAME}/versions.html"
echo "Stable root:      https://noreplymjv.github.io/${SITE_NAME}/"
[ -n "$SLOT" ] && echo "New slot:         https://noreplymjv.github.io/${SITE_NAME}/${SLOT}/"
