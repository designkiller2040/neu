"""Fetch cat clips ONLY from sources whose licence allows reuse (Pexels, Pixabay)."""
import json
import os
import pathlib
from dataclasses import dataclass

import requests

STATE = pathlib.Path("state.json")


@dataclass
class Clip:
    source: str
    id: str
    url: str
    duration: float
    author: str
    page: str


def used_ids() -> set[str]:
    if STATE.exists():
        return set(json.loads(STATE.read_text()).get("used", []))
    return set()


def mark_used(clips: list[Clip]) -> None:
    ids = used_ids() | {f"{c.source}:{c.id}" for c in clips}
    STATE.write_text(json.dumps({"used": sorted(ids)}, indent=2))


def _pexels(query: str, page: int) -> list[Clip]:
    key = os.environ.get("PEXELS_API_KEY")
    if not key:
        return []
    r = requests.get(
        "https://api.pexels.com/videos/search",
        headers={"Authorization": key},
        params={"query": query, "per_page": 40, "page": page, "orientation": "landscape"},
        timeout=30,
    )
    r.raise_for_status()
    clips = []
    for v in r.json().get("videos", []):
        files = [f for f in v["video_files"] if f.get("file_type") == "video/mp4" and f.get("width", 0) >= 1280]
        if not files:
            continue
        best = min(files, key=lambda f: abs(f["width"] - 1920))
        clips.append(Clip("pexels", str(v["id"]), best["link"], v["duration"], v["user"]["name"], v["url"]))
    return clips


def _pixabay(query: str, page: int) -> list[Clip]:
    key = os.environ.get("PIXABAY_API_KEY")
    if not key:
        return []
    r = requests.get(
        "https://pixabay.com/api/videos/",
        params={"key": key, "q": query, "per_page": 50, "page": page},
        timeout=30,
    )
    r.raise_for_status()
    clips = []
    for h in r.json().get("hits", []):
        v = h["videos"].get("large") or h["videos"].get("medium")
        if not v or not v.get("url") or v.get("width", 0) < 1280:
            continue
        clips.append(Clip("pixabay", str(h["id"]), v["url"], h["duration"], h["user"], h["pageURL"]))
    return clips


def find_clips(query: str, needed: int, min_len: float = 4, max_len: float = 40) -> list[Clip]:
    """Return `needed` unused clips, searching successive result pages."""
    seen = used_ids()
    out: list[Clip] = []
    for page in range(1, 6):
        for c in _pexels(query, page) + _pixabay(query, page):
            key = f"{c.source}:{c.id}"
            if key in seen or not (min_len <= c.duration <= max_len):
                continue
            seen.add(key)
            out.append(c)
            if len(out) >= needed:
                return out
    return out


def download(clip: Clip, dest: pathlib.Path) -> pathlib.Path:
    path = dest / f"{clip.source}_{clip.id}.mp4"
    if not path.exists():
        with requests.get(clip.url, stream=True, timeout=60) as r:
            r.raise_for_status()
            with open(path, "wb") as f:
                for chunk in r.iter_content(1 << 20):
                    f.write(chunk)
    return path
