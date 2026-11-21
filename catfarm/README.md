# catfarm

Builds cat compilations from **reuse-licensed** clips (Pexels, Pixabay) and schedules them on YouTube.

## Setup
1. `pip install -r requirements.txt` and install `ffmpeg`.
2. Free API keys: `export PEXELS_API_KEY=...` and/or `export PIXABAY_API_KEY=...`
3. Drop royalty-free music you have rights to into `music/` (YouTube Audio Library works).
4. YouTube: in Google Cloud Console enable *YouTube Data API v3*, create an OAuth **Desktop** client,
   save it as `client_secret.json`. First upload opens a browser to log in.
   Note: uploads from an unaudited API project are locked private until you pass Google's audit (apply via the API Compliance form).

## Run
```sh
python -m catfarm.main --videos 2 --dry-run     # build only
python -m catfarm.main --videos 7 --per-day 1 --shorts --voiceover   # a week of videos + Shorts
```

## Original layer
Each clip gets a funny caption (Claude API if `ANTHROPIC_API_KEY` is set, otherwise built-in templates).
`--voiceover` narrates them (`pip install edge-tts`). `--shorts` also builds a vertical Short per video.

See `MARKETING.md` for the free promotion plan.

## Making money
Monetization needs the YouTube Partner Program (1,000 subs + 4,000 watch hours, or 500 subs + 3 uploads + 3,000 hours
for the early tier). YouTube demonetizes mass-produced/repetitive channels, so add original value:
your own voiceover/captions, varied themes, real thumbnails. Don't post more than 1-2 a day.
Only add music and clips you have rights to.
