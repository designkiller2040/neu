"""Join clips into one 1080p video with a title card and optional royalty-free music."""
import pathlib
import random
import subprocess

FONTS = [
    "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    "C:/Windows/Fonts/arialbd.ttf",
]
VF = "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:black,setsar=1,fps=30,format=yuv420p"


def _run(cmd: list[str]) -> None:
    subprocess.run(cmd, check=True, capture_output=True)


def _font() -> str | None:
    return next((f for f in FONTS if pathlib.Path(f).exists()), None)


def _normalize(src: pathlib.Path, dst: pathlib.Path, max_sec: float, title: str | None) -> None:
    vf = VF
    font = _font()
    if title and font:
        safe = title.replace(":", r"\:").replace("'", "")
        vf += (
            f",drawtext=fontfile='{font}':text='{safe}':fontsize=72:fontcolor=white:"
            "borderw=4:bordercolor=black:x=(w-text_w)/2:y=h*0.8:enable='lt(t,3)'"
        )
    _run(["ffmpeg", "-y", "-i", str(src), "-t", str(max_sec), "-vf", vf, "-an",
          "-c:v", "libx264", "-preset", "veryfast", "-crf", "21", str(dst)])


def build_video(clips: list[pathlib.Path], out: pathlib.Path, title: str,
                music_dir: pathlib.Path | None, max_clip_sec: float = 15) -> pathlib.Path:
    work = out.parent / (out.stem + "_parts")
    work.mkdir(parents=True, exist_ok=True)
    parts = []
    for i, c in enumerate(clips):
        p = work / f"{i:02d}.mp4"
        _normalize(c, p, max_clip_sec, title if i == 0 else None)
        parts.append(p)
    listing = work / "list.txt"
    listing.write_text("".join(f"file '{p.resolve()}'\n" for p in parts))
    joined = work / "joined.mp4"
    _run(["ffmpeg", "-y", "-f", "concat", "-safe", "0", "-i", str(listing), "-c", "copy", str(joined)])

    tracks = sorted(p for p in (music_dir.glob("*") if music_dir else []) if p.suffix.lower() in {".mp3", ".m4a", ".wav"})
    if tracks:
        audio = ["-stream_loop", "-1", "-i", str(random.choice(tracks)), "-af", "volume=0.35"]
    else:
        audio = ["-f", "lavfi", "-i", "anullsrc=r=44100:cl=stereo"]
    _run(["ffmpeg", "-y", "-i", str(joined), *audio, "-map", "0:v", "-map", "1:a",
          "-c:v", "copy", "-c:a", "aac", "-shortest", str(out)])
    return out
