#!/usr/bin/env bash
set -euo pipefail
LOG=/tmp/gmb-move-to-allprojects.log
exec > >(tee -a "$LOG") 2>&1
echo "=== START $(date -Is) ==="
touch /media/mj/DATA/.gmb-move-started && echo DATA_WRITABLE=yes || echo DATA_WRITABLE=no
touch "/media/mj/My Passport/from-DATA/.gmb-move-started" && echo PASSPORT_WRITABLE=yes || echo PASSPORT_WRITABLE=no
echo "=== END probe $(date -Is) ==="
