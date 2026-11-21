"""Original layer: short funny captions per clip (Claude API if ANTHROPIC_API_KEY is set, else templates)."""
import json
import os
import random

FALLBACK = [
    "Me pretending I did not just knock that over.",
    "Plot twist: it was the cat.",
    "Zero thoughts. Maximum fluff.",
    "This is my villain origin story.",
    "Gravity? Never heard of her.",
    "When the snack bag crinkles.",
    "Professional nap taker at work.",
    "I live here now. Pay rent? Never.",
    "Calculating the jump. Fails anyway.",
    "Tiny predator, giant ego.",
    "Monday mood, but with whiskers.",
    "He saw nothing. She saw everything.",
]


def make(n: int) -> list[str]:
    key = os.environ.get("ANTHROPIC_API_KEY")
    if key:
        try:
            import requests
            r = requests.post(
                "https://api.anthropic.com/v1/messages",
                headers={"x-api-key": key, "anthropic-version": "2023-06-01"},
                json={"model": "claude-haiku-5-5", "max_tokens": 800, "messages": [{
                    "role": "user",
                    "content": f"Write {n} different, wholesome, funny one-line captions (max 8 words each) for "
                               "clips in a cat compilation. Reply with only a JSON array of strings."}]},
                timeout=60,
            )
            r.raise_for_status()
            caps = json.loads(r.json()["content"][0]["text"])
            if len(caps) >= n:
                return [str(c) for c in caps[:n]]
        except Exception as e:  # fall back quietly
            print(f"caption API failed ({e}); using templates")
    pool = FALLBACK * ((n // len(FALLBACK)) + 1)
    random.shuffle(pool)
    return pool[:n]
