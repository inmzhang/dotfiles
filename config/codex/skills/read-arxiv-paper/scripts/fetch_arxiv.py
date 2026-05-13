#!/usr/bin/env python3

from __future__ import annotations

import argparse
import gzip
import json
import re
import shutil
import tarfile
import urllib.parse
import urllib.request
from pathlib import Path


ARXIV_HOSTS = {"arxiv.org", "www.arxiv.org"}
DOCUMENTCLASS_RE = re.compile(rb"\\documentclass")
BEGIN_DOCUMENT_RE = re.compile(rb"\\begin\{document\}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Download an arXiv PDF and source bundle into a local paper directory."
    )
    parser.add_argument("paper_ref", help="arXiv id or arXiv abs/pdf/src URL")
    parser.add_argument(
        "--paper-dir",
        type=Path,
        default=Path.cwd(),
        help="Target directory for paper assets (default: current directory)",
    )
    parser.add_argument(
        "--no-pdf",
        action="store_true",
        help="Skip downloading paper.pdf",
    )
    parser.add_argument(
        "--no-source",
        action="store_true",
        help="Skip downloading and extracting the source bundle",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite existing downloads and re-extract the source bundle",
    )
    return parser.parse_args()


def normalize_arxiv_id(raw: str) -> str:
    candidate = raw.strip()
    if not candidate:
        raise ValueError("missing arXiv identifier")

    if candidate.lower().startswith("arxiv:"):
        candidate = candidate.split(":", 1)[1]

    if candidate.startswith(("http://", "https://")):
        parsed = urllib.parse.urlparse(candidate)
        if parsed.netloc not in ARXIV_HOSTS:
            raise ValueError(f"unsupported host: {parsed.netloc}")
        parts = parsed.path.strip("/").split("/")
        if len(parts) < 2 or parts[0] not in {"abs", "pdf", "src"}:
            raise ValueError(f"unsupported arXiv URL path: {parsed.path}")
        candidate = "/".join(parts[1:])

    if candidate.endswith(".pdf"):
        candidate = candidate[: -len(".pdf")]

    return candidate


def download(url: str, destination: Path, force: bool) -> None:
    if destination.exists() and not force and destination.stat().st_size > 0:
        return

    destination.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(url) as response, destination.open("wb") as handle:
        shutil.copyfileobj(response, handle)


def safe_extract(archive: tarfile.TarFile, destination: Path) -> None:
    root = destination.resolve()
    for member in archive.getmembers():
        member_path = (destination / member.name).resolve()
        if not str(member_path).startswith(str(root)):
            raise ValueError(f"blocked path traversal in archive member: {member.name}")
    archive.extractall(destination)


def extract_source_bundle(bundle_path: Path, source_dir: Path, force: bool) -> str:
    if source_dir.exists():
        if force:
            shutil.rmtree(source_dir)
        else:
            return "existing"

    source_dir.mkdir(parents=True, exist_ok=True)

    try:
        with tarfile.open(bundle_path, "r:*") as archive:
            safe_extract(archive, source_dir)
        return "tar"
    except tarfile.ReadError:
        pass

    try:
        with gzip.open(bundle_path, "rb") as archive:
            payload = archive.read()
        (source_dir / "main.tex").write_bytes(payload)
        return "gzip"
    except OSError:
        pass

    shutil.copy2(bundle_path, source_dir / "source.tex")
    return "raw"


def candidate_score(path: Path) -> tuple[int, int]:
    score = 0
    try:
        data = path.read_bytes()
    except OSError:
        return (-1, 0)

    if path.name == "main.tex":
        score += 50
    if DOCUMENTCLASS_RE.search(data):
        score += 30
    if BEGIN_DOCUMENT_RE.search(data):
        score += 10

    depth_penalty = len(path.parts)
    return (score, -depth_penalty)


def find_entrypoint(source_dir: Path) -> str | None:
    tex_files = sorted(source_dir.rglob("*.tex"))
    if not tex_files:
        return None

    ranked = sorted(tex_files, key=candidate_score, reverse=True)
    best = ranked[0]
    if candidate_score(best)[0] < 0:
        return None
    return str(best.relative_to(source_dir))


def write_metadata(
    paper_dir: Path,
    *,
    arxiv_id: str,
    pdf_url: str,
    source_url: str,
    pdf_path: Path | None,
    source_bundle_path: Path | None,
    source_dir: Path | None,
    entrypoint: str | None,
    extraction_mode: str | None,
) -> Path:
    metadata = {
        "arxiv_id": arxiv_id,
        "pdf_url": pdf_url,
        "source_url": source_url,
        "pdf_path": str(pdf_path) if pdf_path else None,
        "source_bundle_path": str(source_bundle_path) if source_bundle_path else None,
        "source_dir": str(source_dir) if source_dir else None,
        "source_entrypoint": entrypoint,
        "source_extraction_mode": extraction_mode,
    }
    target = paper_dir / "paper-meta.json"
    target.write_text(json.dumps(metadata, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return target


def main() -> int:
    args = parse_args()
    arxiv_id = normalize_arxiv_id(args.paper_ref)
    paper_dir = args.paper_dir.resolve()
    paper_dir.mkdir(parents=True, exist_ok=True)

    pdf_url = f"https://arxiv.org/pdf/{arxiv_id}.pdf"
    source_url = f"https://arxiv.org/src/{arxiv_id}"

    pdf_path = None
    source_bundle_path = None
    source_dir = None
    entrypoint = None
    extraction_mode = None

    if not args.no_pdf:
        pdf_path = paper_dir / "paper.pdf"
        download(pdf_url, pdf_path, args.force)

    if not args.no_source:
        source_bundle_path = paper_dir / "paper-source.tar.gz"
        download(source_url, source_bundle_path, args.force)
        source_dir = paper_dir / "source"
        extraction_mode = extract_source_bundle(source_bundle_path, source_dir, args.force)
        entrypoint = find_entrypoint(source_dir)

    metadata_path = write_metadata(
        paper_dir,
        arxiv_id=arxiv_id,
        pdf_url=pdf_url,
        source_url=source_url,
        pdf_path=pdf_path,
        source_bundle_path=source_bundle_path,
        source_dir=source_dir,
        entrypoint=entrypoint,
        extraction_mode=extraction_mode,
    )

    print(f"paper_dir={paper_dir}")
    print(f"arxiv_id={arxiv_id}")
    if pdf_path:
        print(f"paper_pdf={pdf_path}")
    if source_bundle_path:
        print(f"source_bundle={source_bundle_path}")
    if source_dir:
        print(f"source_dir={source_dir}")
    if entrypoint:
        print(f"source_entrypoint={source_dir / entrypoint}")
    print(f"metadata={metadata_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
