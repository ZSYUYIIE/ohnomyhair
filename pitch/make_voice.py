"""Two-voice narration for the v2 pitch: one TTS take per line (guy / girl), stitched per
scene with short natural gaps, plus word timings for the captions.
Reads script_v2.json; writes editor/public/<id>.mp3 and <id>-words.json (v1's format).
Needs: pip install -r requirements.txt
Run: python -I make_voice.py [scene ids...]
"""
import asyncio
import io
import json
import subprocess
import sys
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parent
import edge_tts  # noqa: E402
import imageio_ffmpeg  # noqa: E402

PUB = ROOT / "editor" / "public"
SR = 24000
FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()
GAP_SAME = 0.18   # between two lines by the same speaker
GAP_SWITCH = 0.32  # when the other person picks up
RATE = "+3%"


async def tts(text, voice, tries=5):
    """The free service drops requests now and then: retry with a growing pause."""
    for attempt in range(tries):
        try:
            talk = edge_tts.Communicate(text, voice, rate=RATE, boundary="WordBoundary")
            audio = bytearray()
            words = []
            async for item in talk.stream():
                if item["type"] == "audio":
                    audio += item["data"]
                elif item["type"] == "WordBoundary":
                    words.append(item)
            return bytes(audio), words
        except Exception as e:  # NoAudioReceived, websocket resets
            if attempt == tries - 1:
                raise
            print(f"  retry {attempt + 1} after {type(e).__name__}", flush=True)
            await asyncio.sleep(2 + attempt * 3)


def decode(mp3):
    pcm = subprocess.run([FFMPEG, "-v", "error", "-i", "pipe:0", "-f", "s16le", "-ac", "1", "-ar", str(SR), "pipe:1"],
                         input=mp3, stdout=subprocess.PIPE, check=True).stdout
    return np.frombuffer(pcm, dtype="<i2").astype(np.float32) / 32768


def encode_mp3(x, path):
    buf = io.BytesIO()
    with wave.open(buf, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((np.clip(x, -1, 1) * 32767).astype("<i2").tobytes())
    subprocess.run([FFMPEG, "-y", "-v", "error", "-i", "pipe:0", "-c:a", "libmp3lame", "-b:a", "128k", str(path)],
                   input=buf.getvalue(), check=True)


async def scene_audio(scene):
    parts, words, t = [], [], 0.0
    prev = None
    for line in scene["lines"]:
        if prev is not None:
            gap = GAP_SWITCH if line["speaker"] != prev else GAP_SAME
            parts.append(np.zeros(int(gap * SR), dtype=np.float32))
            t += gap
        mp3, bounds = await tts(line["text"], line["voice"])
        x = decode(mp3)
        for b in bounds:
            words.append({**b, "offset": b["offset"] + int(t * 1e7), "speaker": line["speaker"]})
        parts.append(x)
        t += len(x) / SR
        prev = line["speaker"]
    return np.concatenate(parts), words


async def main(only):
    scenes = json.loads((ROOT / "script_v2.json").read_text(encoding="utf-8"))
    for s in scenes:
        if only and s["id"] not in only:
            continue
        if not s["lines"]:
            print("SKIP (no lines yet)", s["id"])
            continue
        x, words = await scene_audio(s)
        encode_mp3(x, PUB / f"{s['id']}.mp3")
        (PUB / f"{s['id']}-words.json").write_text(json.dumps(words), encoding="utf-8")
        print(f"VOICE {s['id']:11s} {len(x) / SR:5.1f}s {len(words)} words", flush=True)


if __name__ == "__main__":
    asyncio.run(main(sys.argv[1:]))
