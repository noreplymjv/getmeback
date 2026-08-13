#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"
PORT=8765
if command -v python3 >/dev/null 2>&1; then
  PY=python3
elif command -v python >/dev/null 2>&1; then
  PY=python
else
  echo "Python is needed to open GetMeBack on this computer."
  echo "Install Python 3, then double-click this file again."
  read -r _
  exit 1
fi
if ! "$PY" -c "import socket;s=socket.socket();s.bind(('127.0.0.1',$PORT))" 2>/dev/null; then
  PORT=8766
fi
URL="http://127.0.0.1:${PORT}/GetMeBack.html"
if command -v xdg-open >/dev/null 2>&1; then
  (sleep 0.7; xdg-open "$URL") &
elif command -v open >/dev/null 2>&1; then
  (sleep 0.7; open "$URL") &
fi
echo "GetMeBack is running at $URL"
echo "Folder: $HERE"
echo "Leave this window open. Close it to quit."
exec "$PY" -m http.server "$PORT" --bind 127.0.0.1
