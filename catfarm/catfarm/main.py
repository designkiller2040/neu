"""catfarm: build and schedule cat compilations from licensed clips.

  python -m catfarm.main --videos 7 --per-day 1            # build + upload, scheduled
  python -m catfarm.main --videos 2 --dry-run              # build only, no upload
"""
import argparse
import datetime as dt
import pathlib
import random

from . import compile as comp
from . import sources

TITLES = [
    "Cats That Will Make You Laugh Out Loud 😹 Funny Cat Compilation",
    "Cutest Cats of the Day 🐱 Relaxing Cat Video",
    "Try Not to Say Aww: Adorable Cats & Kittens",
    "Cats Being Cats 😸 Chill Cat Compilation",
    "Kittens Doing Kitten Things 🐾 Cute Cat Video",
]


def slots(n: int, per_day: int, first_day: dt.date) -> list[str]:
    hours = [15, 19, 11, 21, 13][:per_day] if per_day <= 5 else list(range(8, 8 + per_day))
    out = []
    for i in range(n):
        d = first_day + dt.timedelta(days=i // per_day)
        t = dt.datetime.combine(d, dt.time(hours[i % per_day] % 24), tzinfo=dt.timezone.utc)
        out.append(t.strftime("%Y-%m-%dT%H:%M:%SZ"))
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--videos", type=int, default=1)
    ap.add_argument("--per-day", type=int, default=1, help="uploads per day (1-2 recommended)")
    ap.add_argument("--clips-per-video", type=int, default=12)
    ap.add_argument("--query", default="cat")
    ap.add_argument("--music-dir", default="music", help="folder of royalty-free tracks you have rights to")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()

    work, outdir = pathlib.Path("work"), pathlib.Path("output")
    work.mkdir(exist_ok=True)
    outdir.mkdir(exist_ok=True)
    music = pathlib.Path(a.music_dir) if pathlib.Path(a.music_dir).is_dir() else None
    when = slots(a.videos, a.per_day, dt.date.today() + dt.timedelta(days=1))

    for i in range(a.videos):
        clips = sources.find_clips(a.query, a.clips_per_video)
        if len(clips) < a.clips_per_video:
            print(f"Only {len(clips)} unused clips left; stopping. Set PEXELS_API_KEY / PIXABAY_API_KEY or change --query.")
            break
        files = [sources.download(c, work) for c in clips]
        title = random.choice(TITLES)
        out = outdir / f"cats_{dt.date.today():%Y%m%d}_{i + 1}.mp4"
        comp.build_video(files, out, title.split(" Funny")[0][:40], music)
        credits = "\n".join(f"- {c.author} ({c.source}): {c.page}" for c in clips)
        desc = (f"{title}\n\nClips licensed for free use. Thanks to the creators:\n{credits}\n\n"
                "Subscribe for new cat videos every day! 🐾")
        sources.mark_used(clips)
        if a.dry_run:
            print(f"built {out} (would publish {when[i]})")
        else:
            from .upload import upload
            vid = upload(out, title, desc, ["cats", "funny cats", "cute cats", "kittens"], when[i])
            print(f"scheduled https://youtu.be/{vid} for {when[i]}")


if __name__ == "__main__":
    main()
