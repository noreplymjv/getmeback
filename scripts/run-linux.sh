#!/usr/bin/env bash
# Run the GetMeBack Linux desktop release binary.
# Usage: ./scripts/run-linux.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

BUNDLE="build/linux/x64/release/bundle/getmeback"

if [ ! -x "$BUNDLE" ]; then
  echo "Error: $BUNDLE not found. Run 'flutter build linux --release' first."
  exit 1
fi

exec "$BUNDLE" "$@"
