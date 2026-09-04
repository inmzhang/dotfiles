#!/usr/bin/env python3
import functools
import fcntl
import hashlib
import http.server
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
import webbrowser


WATCH_PAGE = """<!doctype html>
<meta charset="utf-8">
<title></title>
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

PREVIEW_STYLE = """<style>
:root { color-scheme: light dark; }
html { scroll-behavior: smooth; }
body {
  box-sizing: border-box;
  max-width: 64rem;
  margin: 0 auto;
  padding: 2rem 2rem 5rem 16rem;
  font: 16px/1.6 system-ui;
}
#TOC {
  position: fixed;
  top: 1rem;
  left: max(1rem, calc(50vw - 31rem));
  width: 12rem;
  max-height: calc(100vh - 2rem);
  overflow: auto;
}
#TOC ol { padding-left: 1.5rem; }
#TOC a { color: inherit; }
.label {
  display: inline-block;
  margin-right: .35rem;
  padding: 0 .45rem;
  border-radius: .4rem;
  color: white;
  font-weight: 700;
}
.question { background: #4f46e5; }
.answer { background: #0f766e; }
.message {
  display: grid;
  grid-template-columns: auto minmax(0, 1fr);
  column-gap: .75rem;
  align-items: start;
}
.message > :first-child { margin: 0; }
.message > :not(:first-child) { grid-column: 2; }
.message > :nth-child(2) { margin-top: 0; }
pre { overflow: auto; }
img { max-width: 100%; }
@media (max-width: 52rem) {
  body { padding: 1rem; }
  #TOC { position: static; width: auto; max-height: none; }
}
</style>
"""


class PreviewHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, workspace, **kwargs):
        self.workspace = workspace.resolve()
        super().__init__(*args, **kwargs)

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
        if self.serve_workspace_file():
            return
        super().do_GET()

    def serve_workspace_file(self):
        request_path = urllib.parse.unquote(urllib.parse.urlsplit(self.path).path)
        if request_path in {"/", "/index.html", "/preview.html"}:
            return False
        request_path = re.sub(r":\d+(?::\d+)?$", "", request_path)
        candidate = Path(request_path)
        if not candidate.is_relative_to(self.workspace):
            candidate = self.workspace / request_path.lstrip("/")
        try:
            candidate = candidate.resolve(strict=True)
            candidate.relative_to(self.workspace)
        except (OSError, ValueError):
            return False
        if not candidate.is_file():
            return False

        with candidate.open("rb") as source:
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", str(candidate.stat().st_size))
            self.send_header("Content-Security-Policy", "default-src 'none'")
            self.send_header("X-Content-Type-Options", "nosniff")
            self.end_headers()
            self.copyfile(source, self.wfile)
        return True

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


def prompt_path(event, output_dir):
    turn_id = event.get("turn_id")
    if not isinstance(turn_id, str) or not turn_id:
        raise ValueError("missing Codex turn_id")
    turn_key = hashlib.sha256(turn_id.encode()).hexdigest()[:16]
    return output_dir / f".prompt-{turn_key}.md"


def markdown_document(history):
    navigation = ["<nav id=\"TOC\" aria-label=\"Turn history\"><strong>Turns</strong><ol>"]
    sections = []
    for index in range(len(history) - 1, -1, -1):
        number = index + 1
        navigation.append(f'<li><a href="#turn-{number}">Q{number}</a></li>')
        turn = history[index]
        sections.extend([
            f'::::: {{#turn-{number} .message}}',
            '<span class="label question">Q:</span>',
            "",
            turn["prompt"] or "_Prompt unavailable._",
            ":::::",
            "",
            "::::: {.message}",
            '<span class="label answer">A:</span>',
            "",
            turn["assistant"],
            ":::::",
            "",
            "---",
            "",
        ])
    navigation.append("</ol></nav>")
    return "\n".join(navigation + [""] + sections)


def render(event, output_dir, history):
    document = markdown_document(history)

    output_dir.mkdir(parents=True, exist_ok=True)
    temporary = output_dir / f".preview-{os.getpid()}.html"
    header = output_dir / f".header-{os.getpid()}.html"
    try:
        header.write_text(PREVIEW_STYLE, encoding="utf-8")
        subprocess.run(
            [
                os.environ.get("PANDOC_PATH", "pandoc"),
                "--from", "markdown+tex_math_dollars+tex_math_single_backslash",
                "--to", "html5",
                "--standalone",
                "--mathml",
                "--embed-resources",
                "--include-in-header", str(header),
                "--resource-path", event.get("cwd") or os.getcwd(),
                "--metadata", "pagetitle=",
                "--output", str(temporary),
                "-",
            ],
            input=document,
            text=True,
            check=True,
        )
        temporary.replace(output_dir / "preview.html")
    finally:
        temporary.unlink(missing_ok=True)
        header.unlink(missing_ok=True)


def save_prompt(event, output_dir):
    prompt = event.get("prompt")
    if not isinstance(prompt, str):
        raise ValueError("missing Codex prompt")
    output_dir.mkdir(parents=True, exist_ok=True)
    prompt_path(event, output_dir).write_text(prompt, encoding="utf-8")


def archive_turn(event, output_dir):
    message = event.get("last_assistant_message")
    if not message:
        return

    output_dir.mkdir(parents=True, exist_ok=True)
    history_path = output_dir / "history.json"
    pending_prompt = prompt_path(event, output_dir)
    with (output_dir / "history.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        try:
            history = json.loads(history_path.read_text(encoding="utf-8"))
        except FileNotFoundError:
            history = []
        if not isinstance(history, list):
            raise ValueError("invalid markdown preview history")

        turn_id = event["turn_id"]
        existing = next((turn for turn in history if turn.get("turn_id") == turn_id), None)
        try:
            prompt = pending_prompt.read_text(encoding="utf-8")
        except FileNotFoundError:
            prompt = existing.get("prompt", "") if existing else ""
        turn = {"turn_id": turn_id, "prompt": prompt, "assistant": message}
        if existing:
            history[history.index(existing)] = turn
        else:
            history.append(turn)

        temporary = output_dir / f".history-{os.getpid()}.json"
        temporary.write_text(json.dumps(history, ensure_ascii=False), encoding="utf-8")
        temporary.replace(history_path)
        render(event, output_dir, history)
        pending_prompt.unlink(missing_ok=True)


def server_is_up(port):
    try:
        with DIRECT_OPENER.open(f"http://127.0.0.1:{port}/__health__", timeout=0.2) as response:
            return response.status == 204
    except (OSError, ValueError, urllib.error.URLError):
        return False


def ensure_server(output_dir, workspace):
    port_file = output_dir / "port"
    try:
        port = int(port_file.read_text())
        if server_is_up(port):
            return port, False
    except (OSError, ValueError):
        pass

    port_file.unlink(missing_ok=True)
    subprocess.Popen(
        [sys.executable, str(Path(__file__).resolve()), "--serve", str(output_dir), workspace],
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


def run_server(output_dir, workspace):
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "index.html").write_text(WATCH_PAGE, encoding="utf-8")
    handler = functools.partial(
        PreviewHandler,
        directory=str(output_dir),
        workspace=Path(workspace),
    )
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
    if event.get("hook_event_name") == "UserPromptSubmit":
        save_prompt(event, output_dir)
    elif event.get("hook_event_name") == "Stop":
        archive_turn(event, output_dir)
        port, started = ensure_server(output_dir, event.get("cwd") or os.getcwd())
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
        common = {
            "session_id": "markdown-preview-check",
            "cwd": os.getcwd(),
        }

        def invoke(hook_event_name, **fields):
            event = common | {"hook_event_name": hook_event_name} | fields
            result = subprocess.run(
                [sys.executable, str(Path(__file__).resolve())],
                input=json.dumps(event),
                text=True,
                capture_output=True,
                env=environment,
                check=True,
            )
            assert result.stdout.strip() == "{}"

        try:
            invoke("UserPromptSubmit", turn_id="one", prompt="First prompt")
            invoke(
                "Stop",
                turn_id="one",
                last_assistant_message=r"Euler: $e^{i\pi}+1=0$",
            )
            invoke("UserPromptSubmit", turn_id="two", prompt="- Second prompt\n- Prompt item")
            invoke(
                "Stop",
                turn_id="two",
                last_assistant_message=f"- Second answer\n- [hook]({Path(__file__).resolve()}:1)",
            )
            previews = list((Path(cache_root) / "codex" / "markdown-preview").glob("*/preview.html"))
            assert len(previews) == 1
            preview = previews[0].read_text(encoding="utf-8")
            assert "<math" in preview and 'href="#turn-2"' in preview
            assert preview.index("Second answer") < preview.index("Euler")
            assert "First prompt" in preview and "Second prompt" in preview
            assert "Turn 1" not in preview and 'class="label answer"' in preview
            assert "Codex Markdown Preview" not in preview
            assert "<li>Second prompt</li>" in preview and "<li>Second answer</li>" in preview

            port = int((previews[0].parent / "port").read_text())
            hook_path = Path(__file__).resolve()
            with DIRECT_OPENER.open(f"http://127.0.0.1:{port}{hook_path}:1") as response:
                assert response.headers.get_content_type() == "text/plain"
                assert response.read(22).startswith(b"#!/usr/bin/env python3")
            try:
                DIRECT_OPENER.open(f"http://127.0.0.1:{port}/etc/passwd")
            except urllib.error.HTTPError as error:
                assert error.code == 404
            else:
                raise AssertionError("preview exposed a file outside the workspace")
        finally:
            invoke("SessionEnd")
    print("ok")
    return 0


if __name__ == "__main__":
    try:
        if sys.argv[1:2] == ["--serve"]:
            status = run_server(Path(sys.argv[2]), sys.argv[3])
        elif sys.argv[1:2] == ["--check"]:
            status = run_check()
        else:
            status = run_hook()
        raise SystemExit(status)
    except Exception as error:
        print(f"markdown preview: {error}", file=sys.stderr)
        raise SystemExit(1)
