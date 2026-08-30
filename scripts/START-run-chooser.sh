#!/usr/bin/env bash
# Open GetMeBack device chooser (Linux vs Chrome) in the browser.
# Portable: uses AllProjects/.portable-sdk when present.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
AP_SDK="$(cd "$ROOT/../.portable-sdk" 2>/dev/null && pwd || true)"
TOOLING_FLUTTER="$ROOT/.tooling/flutter/bin/flutter"

if [ -f "${AP_SDK:-}/activate.sh" ]; then
  # shellcheck disable=SC1091
  source "$AP_SDK/activate.sh"
elif [ -x "$TOOLING_FLUTTER" ]; then
  export PATH="$(dirname "$TOOLING_FLUTTER"):$PATH"
  export FLUTTER_ROOT="$(cd "$(dirname "$TOOLING_FLUTTER")/.." && pwd)"
fi

export GETMEBACK_APP_ROOT="$ROOT"
cd "$ROOT"

PY=python3
command -v "$PY" >/dev/null 2>&1 || PY=python
if ! command -v "$PY" >/dev/null 2>&1; then
  echo "Python 3 is required for the chooser."
  exit 1
fi

exec "$PY" "$SCRIPT_DIR/run-chooser-server.py"
