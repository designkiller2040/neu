"""catfarm: build and schedule cat compilations from licensed clips.

  python -m catfarm.main --videos 7 --per-day 1            # build + upload, scheduled
  python -m catfarm.main --videos 2 --dry-run              # build only, no upload
"""
import argparse
import datetime as dt
import pathlib
import random

from . import captions as capmod
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
    ap.add_argument("--voiceover", action="store_true", help="narrate captions (needs: pip install edge-tts)")
    ap.add_argument("--shorts", action="store_true", help="also make a vertical Short per video (free marketing)")
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
        caps = capmod.make(len(files))
        voices = [comp.voice(t, work / f"v{i}_{j}.mp3") for j, t in enumerate(caps)] if a.voiceover else None
        comp.build_video(files, out, title.split(" Funny")[0][:40], music, caps, voices)
        credits = "\n".join(f"- {c.author} ({c.source}): {c.page}" for c in clips)
        desc = (f"{title}\n\nClips licensed for free use. Thanks to the creators:\n{credits}\n\n"
                "Subscribe for new cat videos every day! 🐾")
        sources.mark_used(clips)
        short = None
        if a.shorts:
            short = outdir / f"short_{out.stem}.mp4"
            comp.build_short(files[:4], short, "Cats 😹", music, caps[:4], voices[:4] if voices else None)
        if a.dry_run:
            print(f"built {out}" + (f" + {short}" if short else "") + f" (would publish {when[i]})")
            continue
        from .upload import upload
        tags = ["cats", "funny cats", "cute cats", "kittens"]
        vid = upload(out, title, desc, tags, when[i])
        print(f"scheduled https://youtu.be/{vid} for {when[i]}")
        if short:  # publish the Short ~4h before the long video, linking to it
            sdesc = f"Full video: https://youtu.be/{vid}\n\n#Shorts #cats\n\n{credits}"
            sat = (dt.datetime.fromisoformat(when[i].replace("Z", "+00:00")) - dt.timedelta(hours=4)).strftime("%Y-%m-%dT%H:%M:%SZ")
            sid = upload(short, "Cats being cats 😹 #Shorts", sdesc, tags + ["shorts"], sat)
            print(f"scheduled Short https://youtu.be/{sid} for {sat}")


if __name__ == "__main__":
    main()
