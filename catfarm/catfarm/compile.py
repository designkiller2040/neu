"""Join clips into one 1080p video: title card, burned-in captions, optional voiceover and music."""
import pathlib
import random
import shutil
import subprocess
import textwrap

FONTS = [
    "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    "C:/Windows/Fonts/arialbd.ttf",
]
VF = "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:black,setsar=1,fps=30,format=yuv420p"
VF_SHORT = "scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,setsar=1,fps=30,format=yuv420p"
VF_ACTIVE: dict = {}
TEXT = "fontfile='{font}':textfile='{tf}':fontsize={size}:fontcolor=white:borderw=4:bordercolor=black:x=(w-text_w)/2:y={y}{extra}"


def _run(cmd: list[str]) -> None:
    subprocess.run(cmd, check=True, capture_output=True)


def _font() -> str | None:
    return next((f for f in FONTS if pathlib.Path(f).exists()), None)


def _text(work: pathlib.Path, name: str, text: str, size: int, y: str, extra: str = "") -> str:
    font = _font()
    if not font or not text:
        return ""
    tf = work / f"{name}.txt"
    width = int((1080 if "1080:1920" in VF_ACTIVE.get("vf", "") else 1920) * 0.85 / (size * 0.62))
    clean = "".join(ch for ch in text if ord(ch) < 0x2600).strip()
    tf.write_text("\n".join(textwrap.wrap(clean, width)))
    return "," + "drawtext=" + TEXT.format(font=font, tf=str(tf).replace(":", r"\:"), size=size, y=y, extra=extra)


def voice(text: str, dst: pathlib.Path) -> pathlib.Path | None:
    """Optional voiceover via the free `edge-tts` CLI (pip install edge-tts). Returns None if unavailable."""
    if not shutil.which("edge-tts"):
        return None
    try:
        _run(["edge-tts", "--voice", "en-US-GuyNeural", "--text", text, "--write-media", str(dst)])
        return dst
    except subprocess.CalledProcessError:
        return None


def _normalize(src, dst, work, i, max_sec, vf, caption, title, voice_file, size=56, y="h*0.86"):
    VF_ACTIVE["vf"] = vf
    vf += _text(work, f"cap{i}", caption, size, y)
    if title:
        vf += _text(work, "title", title, size + 24, "h*0.08", ":enable='lt(t,3)'")
    if voice_file:
        a_in = ["-i", str(voice_file)]
    else:
        a_in = ["-f", "lavfi", "-i", "anullsrc=r=44100:cl=stereo"]
    _run(["ffmpeg", "-y", "-i", str(src), *a_in, "-t", str(max_sec), "-vf", vf,
          "-map", "0:v", "-map", "1:a", "-af", "apad", "-ar", "44100", "-ac", "2", "-shortest",
          "-c:v", "libx264", "-preset", "veryfast", "-crf", "21", "-c:a", "aac", str(dst)])


def _concat(parts, work):
    listing = work / "list.txt"
    listing.write_text("".join(f"file '{p.resolve()}'\n" for p in parts))
    joined = work / "joined.mp4"
    _run(["ffmpeg", "-y", "-f", "concat", "-safe", "0", "-i", str(listing), "-c", "copy", str(joined)])
    return joined


def _mix_music(joined, out, music_dir):
    tracks = sorted(p for p in (music_dir.glob("*") if music_dir else []) if p.suffix.lower() in {".mp3", ".m4a", ".wav"})
    if not tracks:
        shutil.copy(joined, out)
        return
    _run(["ffmpeg", "-y", "-i", str(joined), "-stream_loop", "-1", "-i", str(random.choice(tracks)),
          "-filter_complex", "[1:a]volume=0.25[m];[0:a][m]amix=inputs=2:duration=first[a]",
          "-map", "0:v", "-map", "[a]", "-c:v", "copy", "-c:a", "aac", str(out)])


def build_video(clips, out, title, music_dir, captions=None, voices=None, max_clip_sec=15):
    work = out.parent / (out.stem + "_parts")
    work.mkdir(parents=True, exist_ok=True)
    parts = []
    for i, c in enumerate(clips):
        p = work / f"{i:02d}.mp4"
        _normalize(c, p, work, i, max_clip_sec, VF, (captions or [""] * len(clips))[i],
                   title if i == 0 else None, (voices or [None] * len(clips))[i])
        parts.append(p)
    _mix_music(_concat(parts, work), out, music_dir)
    return out


def build_short(clips, out, title, music_dir, captions=None, voices=None, max_clip_sec=7):
    """Vertical 9:16 Short (<=60s) from a few clips: free marketing funnel to the long videos."""
    work = out.parent / (out.stem + "_parts")
    work.mkdir(parents=True, exist_ok=True)
    parts = []
    for i, c in enumerate(clips):
        p = work / f"{i:02d}.mp4"
        _normalize(c, p, work, i, max_clip_sec, VF_SHORT, (captions or [""] * len(clips))[i],
                   title if i == 0 else None, (voices or [None] * len(clips))[i], size=64, y="h*0.78")
        parts.append(p)
    _mix_music(_concat(parts, work), out, music_dir)
    return out
