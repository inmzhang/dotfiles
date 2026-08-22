#!/usr/bin/env python3
import functools
import hashlib
import http.server
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import threading
import time
import urllib.error
import urllib.request
import webbrowser


WATCH_PAGE = """<!doctype html>
<meta charset="utf-8">
<title>Codex Markdown Preview</title>
<style>
html, body, iframe { width: 100%; height: 100%; margin: 0; border: 0 }
body { display: grid; place-items: center; font: 16px system-ui }
</style>
<p id="waiting">Waiting for a completed Codex response…</p>
<iframe id="preview" hidden></iframe>
<script>
const frame = document.querySelector("#preview");
const waiting = document.querySelector("#waiting");
let current = "";
async function refresh() {
  try {
    const response = await fetch("preview.html", {cache: "no-store"});
    if (!response.ok) return;
    const html = await response.text();
    if (html === current) return;
    current = html;
    waiting.hidden = true;
    frame.hidden = false;
    frame.srcdoc = html;
  } catch {}
}
refresh();
setInterval(refresh, 500);
</script>
"""


class PreviewHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/__health__":
            self.send_response(204)
            self.end_headers()
            return
        if self.path == "/__shutdown__":
            self.send_response(204)
            self.end_headers()
            threading.Thread(target=self.server.shutdown, daemon=True).start()
            return
        super().do_GET()

    def log_message(self, _format, *args):
        pass


DIRECT_OPENER = urllib.request.build_opener(urllib.request.ProxyHandler({}))


def preview_dir(event):
    session_id = event.get("session_id")
    if not isinstance(session_id, str) or not session_id:
        raise ValueError("missing Codex session_id")
    session_key = hashlib.sha256(session_id.encode()).hexdigest()[:16]
    root = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
    return root / "codex" / "markdown-preview" / session_key


def render(event, output_dir):
    message = event.get("last_assistant_message")
    if not message:
        return

    output_dir.mkdir(parents=True, exist_ok=True)
    temporary = output_dir / f".preview-{os.getpid()}.html"
    try:
        subprocess.run(
            [
                os.environ.get("PANDOC_PATH", "pandoc"),
                "--from", "markdown+tex_math_dollars+tex_math_single_backslash",
                "--to", "html5",
                "--standalone",
                "--mathml",
                "--embed-resources",
                "--resource-path", event.get("cwd") or os.getcwd(),
                "--metadata", "title=Codex Markdown Preview",
                "--output", str(temporary),
                "-",
            ],
            input=message,
            text=True,
            check=True,
        )
        temporary.replace(output_dir / "preview.html")
    finally:
        temporary.unlink(missing_ok=True)


def server_is_up(port):
    try:
        with DIRECT_OPENER.open(f"http://127.0.0.1:{port}/__health__", timeout=0.2) as response:
            return response.status == 204
    except (OSError, ValueError, urllib.error.URLError):
        return False


def ensure_server(output_dir):
    port_file = output_dir / "port"
    try:
        port = int(port_file.read_text())
        if server_is_up(port):
            return port, False
    except (OSError, ValueError):
        pass

    port_file.unlink(missing_ok=True)
    subprocess.Popen(
        [sys.executable, str(Path(__file__).resolve()), "--serve", str(output_dir)],
        start_new_session=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    deadline = time.monotonic() + 2
    while time.monotonic() < deadline:
        try:
            port = int(port_file.read_text())
            if server_is_up(port):
                return port, True
        except (OSError, ValueError):
            pass
        time.sleep(0.05)
    raise RuntimeError("preview server failed to start")


def stop_server(output_dir):
    try:
        port = int((output_dir / "port").read_text())
        DIRECT_OPENER.open(f"http://127.0.0.1:{port}/__shutdown__", timeout=0.5).close()
    except (OSError, ValueError, urllib.error.URLError):
        pass


def run_server(output_dir):
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "index.html").write_text(WATCH_PAGE, encoding="utf-8")
    handler = functools.partial(PreviewHandler, directory=str(output_dir))
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
    (output_dir / "port").write_text(str(server.server_port))
    try:
        server.serve_forever(poll_interval=0.05)
    finally:
        server.server_close()
        (output_dir / "port").unlink(missing_ok=True)
    return 0


def run_hook():
    event = json.load(sys.stdin)
    output_dir = preview_dir(event)
    if event.get("hook_event_name") == "Stop":
        render(event, output_dir)
        port, started = ensure_server(output_dir)
        if started:
            webbrowser.open(f"http://127.0.0.1:{port}/")
    elif event.get("hook_event_name") == "SessionEnd":
        stop_server(output_dir)
    print("{}")
    return 0


def run_check():
    with tempfile.TemporaryDirectory() as cache_root:
        environment = os.environ.copy()
        environment["XDG_CACHE_HOME"] = cache_root
        environment["BROWSER"] = "true"
        event = {
            "hook_event_name": "Stop",
            "session_id": "markdown-preview-check",
            "cwd": os.getcwd(),
            "last_assistant_message": r"Euler: $e^{i\pi}+1=0$",
        }
        try:
            result = subprocess.run(
                [sys.executable, str(Path(__file__).resolve())],
                input=json.dumps(event),
                text=True,
                capture_output=True,
                env=environment,
                check=True,
            )
            previews = list((Path(cache_root) / "codex" / "markdown-preview").glob("*/preview.html"))
            assert result.stdout.strip() == "{}"
            assert len(previews) == 1 and "<math" in previews[0].read_text()
        finally:
            event["hook_event_name"] = "SessionEnd"
            subprocess.run(
                [sys.executable, str(Path(__file__).resolve())],
                input=json.dumps(event),
                text=True,
                capture_output=True,
                env=environment,
                check=False,
            )
    print("ok")
    return 0


if __name__ == "__main__":
    try:
        if sys.argv[1:2] == ["--serve"]:
            status = run_server(Path(sys.argv[2]))
        elif sys.argv[1:2] == ["--check"]:
            status = run_check()
        else:
            status = run_hook()
        raise SystemExit(status)
    except Exception as error:
        print(f"markdown preview: {error}", file=sys.stderr)
        raise SystemExit(1)
