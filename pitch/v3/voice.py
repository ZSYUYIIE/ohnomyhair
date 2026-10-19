"""Replaceable per-line/per-section voice tracks with exact TTS word boundaries."""
import asyncio
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PITCH = ROOT.parent
sys.path.insert(0, str(PITCH))
from make_voice import decode, encode_mp3, tts as one_tts, SR  # noqa: E402
import numpy as np  # noqa: E402
from script import VOICES  # noqa: E402

PUB = PITCH / "editor/public/v3/voice"


async def tts(text, voice):
    for attempt in range(14):
        try:
            return await one_tts(text, voice, tries=1)
        except Exception as error:
            if attempt == 13:
                raise
            print(f"  TTS reconnect {attempt+1}: {type(error).__name__}", flush=True)
            await asyncio.sleep(min(1 + attempt, 4))


async def main(only):
    PUB.mkdir(parents=True, exist_ok=True)
    scenes = json.loads((ROOT / "script.json").read_text(encoding="utf-8"))
    for scene in scenes:
        if only and scene["id"] not in only:
            continue
        parts, words, cursor, cues = [], [], 0.0, []
        for i, line in enumerate(scene["lines"]):
            stem = PUB / f"{scene['id']}-{i+1:02}"
            key = hashlib.sha256((VOICES[line["speaker"]] + line["text"]).encode()).hexdigest()
            meta = stem.with_suffix(".json")
            if meta.exists() and stem.with_suffix(".mp3").exists() and json.loads(meta.read_text())["key"] == key:
                saved = json.loads(meta.read_text())
                audio = stem.with_suffix(".mp3").read_bytes()
                bounds = saved["words"]
            else:
                audio, bounds = await tts(line["text"], VOICES[line["speaker"]])
                stem.with_suffix(".mp3").write_bytes(audio)
                meta.write_text(json.dumps({"key": key, "words": bounds}), encoding="utf-8")
            x = decode(audio)
            start = float(line.get("at", cursor + (.30 if i else 0)))
            if start < cursor:
                raise ValueError(f"Voice overlap in {scene['id']}: {start} < {cursor}")
            parts.append(np.zeros(round((start - cursor) * SR), dtype=np.float32))
            parts.append(x)
            for b in bounds:
                words.append({"text": b["text"], "start": start + b["offset"] / 1e7,
                              "end": start + (b["offset"] + b["duration"]) / 1e7, "speaker": line["speaker"]})
            cursor = start + len(x) / SR
            cues.append({"line": i + 1, "start": start, "end": cursor, "speaker": line["speaker"], "text": line["text"]})
        encode_mp3(np.concatenate(parts), PUB / f"{scene['id']}.mp3")
        (PUB / f"{scene['id']}-timing.json").write_text(json.dumps({"seconds": cursor, "lines": cues, "words": words}, indent=2), encoding="utf-8")
        print(f"VOICE {scene['id']:10} {cursor:5.2f}s", flush=True)


if __name__ == "__main__":
    asyncio.run(main(sys.argv[1:]))
