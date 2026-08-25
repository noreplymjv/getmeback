#!/usr/bin/env bash
# Probe writability of optional external volumes (env-driven; no hardcoded mounts).
# Example:
#   GETMEBACK_DATA_PROBE=/path/to/data GETMEBACK_PASSPORT_PROBE=/path/to/passport \
#     ./scripts/MOVE_TO_ALLPROJECTS.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG="${GETMEBACK_MOVE_LOG:-/tmp/gmb-move-to-allprojects.log}"
exec > >(tee -a "$LOG") 2>&1

echo "=== START $(date -Is) ==="
echo "ROOT=$ROOT"

DATA_PROBE="${GETMEBACK_DATA_PROBE:-}"
PASSPORT_PROBE="${GETMEBACK_PASSPORT_PROBE:-}"

if [ -n "$DATA_PROBE" ]; then
  touch "$DATA_PROBE/.gmb-move-started" && echo DATA_WRITABLE=yes || echo DATA_WRITABLE=no
else
  echo "DATA_PROBE unset (set GETMEBACK_DATA_PROBE to test a volume)"
fi

if [ -n "$PASSPORT_PROBE" ]; then
  touch "$PASSPORT_PROBE/.gmb-move-started" && echo PASSPORT_WRITABLE=yes || echo PASSPORT_WRITABLE=no
else
  echo "PASSPORT_PROBE unset (set GETMEBACK_PASSPORT_PROBE to test a volume)"
fi

echo "=== END probe $(date -Is) ==="
