#!/usr/bin/env python3
"""Local launcher for GetMeBack: HTML chooser → flutter run -d linux|chrome."""

from __future__ import annotations

import os
import shutil
import signal
import subprocess
import sys
import threading
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

ROOT = Path(os.environ.get("GETMEBACK_APP_ROOT", Path(__file__).resolve().parents[1]))
HTML = ROOT / "launchers" / "run-chooser.html"
PORT = int(os.environ.get("GETMEBACK_CHOOSER_PORT", "8791"))

_flutter_proc: subprocess.Popen | None = None
_lock = threading.Lock()


def find_flutter() -> str:
    env = os.environ.get("FLUTTER_BIN")
    if env and Path(env).is_file() and os.access(env, os.X_OK):
        return env
    for candidate in (
        ROOT / ".tooling" / "flutter" / "bin" / "flutter",
        ROOT.parent / ".portable-sdk" / "flutter" / "bin" / "flutter",
        ROOT.parent.parent / ".portable-sdk" / "flutter" / "bin" / "flutter",
    ):
        if candidate.is_file() and os.access(candidate, os.X_OK):
            return str(candidate)
    which = shutil.which("flutter")
    if which:
        return which
    raise FileNotFoundError(
        "flutter not found. source AllProjects/.portable-sdk/activate.sh first."
    )


def stop_flutter() -> None:
    global _flutter_proc
    with _lock:
        if _flutter_proc and _flutter_proc.poll() is None:
            _flutter_proc.send_signal(signal.SIGTERM)
            try:
                _flutter_proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                _flutter_proc.kill()
        _flutter_proc = None


def start_flutter(device: str) -> tuple[bool, str]:
    global _flutter_proc
    if device not in ("linux", "chrome"):
        return False, "device must be linux or chrome"
    try:
        flutter = find_flutter()
    except FileNotFoundError as e:
        return False, str(e)

    stop_flutter()
    cmd = [flutter, "run", "-d", device]
    log_path = ROOT / "launchers" / f"flutter-run-{device}.log"
    log_path.parent.mkdir(parents=True, exist_ok=True)
    logf = open(log_path, "w", encoding="utf-8")
    env = os.environ.copy()
    with _lock:
        _flutter_proc = subprocess.Popen(
            cmd,
            cwd=str(ROOT),
            env=env,
            stdout=logf,
            stderr=subprocess.STDOUT,
            start_new_session=True,
        )
        pid = _flutter_proc.pid
    return True, f"Started: {' '.join(cmd)} (pid {pid}). Log: {log_path}"


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt: str, *args) -> None:
        sys.stderr.write("[chooser] " + (fmt % args) + "\n")

    def _cors(self) -> None:
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def do_OPTIONS(self) -> None:
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_GET(self) -> None:
        path = urlparse(self.path).path
        if path in ("/", "/index.html", "/run-chooser.html"):
            body = HTML.read_bytes()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self._cors()
            self.end_headers()
            self.wfile.write(body)
            return
        if path == "/status":
            running = _flutter_proc is not None and _flutter_proc.poll() is None
            msg = b'{"ok":true,"running":%s}' % (b"true" if running else b"false")
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(msg)))
            self._cors()
            self.end_headers()
            self.wfile.write(msg)
            return
        self.send_error(404)

    def do_POST(self) -> None:
        path = urlparse(self.path).path
        length = int(self.headers.get("Content-Length", 0))
        raw = self.rfile.read(length).decode("utf-8", errors="replace") if length else ""
        qs = parse_qs(raw)
        if path == "/run":
            device = (qs.get("device") or [""])[0].strip()
            ok, message = start_flutter(device)
            body = ('{"ok":%s,"message":%s}' % (
                "true" if ok else "false",
                _json_str(message),
            )).encode()
            self.send_response(200 if ok else 400)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self._cors()
            self.end_headers()
            self.wfile.write(body)
            return
        if path == "/stop":
            stop_flutter()
            body = b'{"ok":true,"message":"Stopped flutter run"}'
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self._cors()
            self.end_headers()
            self.wfile.write(body)
            return
        self.send_error(404)


def _json_str(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'


def main() -> int:
    if not HTML.is_file():
        print(f"Missing chooser HTML: {HTML}", file=sys.stderr)
        return 1
    # Bind localhost only
    httpd = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    url = f"http://127.0.0.1:{PORT}/"
    print(f"GetMeBack run chooser: {url}")
    print(f"App root: {ROOT}")
    print("Leave this terminal open. Ctrl+C to quit.")
    threading.Timer(0.6, lambda: webbrowser.open(url)).start()
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping…")
    finally:
        stop_flutter()
        httpd.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
