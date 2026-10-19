"""Cloned-voice narration for the v2 pitch (Chatterbox, local GPU).
Same outputs as make_voice.py (editor/public/<id>.mp3 + <id>-words.json), but each speaker's
lines are spoken in a voice cloned from a short sample of that person.

Each line is generated, transcribed with faster-whisper and compared with the script; takes
that drop or garble words are regenerated (best of up to TRIES). Whisper's word times drive
the captions, with the script's own spelling and punctuation.

Run with the venv from requirements-clone.txt (CUDA PyTorch + chatterbox-tts):
  .venv-clone/Scripts/python -I make_voice_cb.py --ref A=<sample> --ref B=<sample> [scene ids...]
"""
import argparse
import os
import warnings
import difflib
import io
import json
import random
import re
import subprocess
import wave
import zlib
from pathlib import Path

os.environ.setdefault("TQDM_DISABLE", "1")
warnings.filterwarnings("ignore")
import librosa
import numpy as np
import torch

ROOT = Path(__file__).resolve().parent
PUB = ROOT / "editor" / "public"
CACHE = ROOT / "cb_cache"
import imageio_ffmpeg  # noqa: E402

FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()
SR = 24000
TRIES = 3
GOOD_ENOUGH = 0.85       # share of script words heard (names and numbers skipped) to accept a take
GAP_SAME = (0.14, 0.24)  # pause range between two lines by the same speaker
GAP_SWITCH = (0.26, 0.42)  # pause range when the other person picks up


NUMBER_WORDS = set("zero one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen "
                   "sixteen seventeen eighteen nineteen twenty thirty forty fifty sixty seventy eighty ninety "
                   "hundred thousand percent".split())


def norm_words(text):
    return [w for w in re.sub(r"[^a-z0-9' ]", " ", text.lower().replace("-", " ")).split() if w]


def match(script_text, heard_text):
    """Share of the script's words that were said, in order. Names and numbers are skipped
    (whisper writes 48 for forty-eight and spells handles out); babbling far past the script
    counts against the take."""
    target = [w for w in norm_words(script_text)
              if w not in NUMBER_WORDS and not any(c.isdigit() for c in w) and w not in ("zsyuyiie", "chenhongshan333")]
    heard = [w for w in norm_words(heard_text) if not any(c.isdigit() for c in w)]
    if not target:
        return 1.0
    sm = difflib.SequenceMatcher(None, target, heard, autojunk=False)
    recall = sum(b.size for b in sm.get_matching_blocks()) / len(target)
    excess = max(0, len(heard) - 1.4 * len(norm_words(script_text)) - 4)
    return recall - 0.05 * excess


def to_wav(path, out):
    """Any phone format (m4a, mp3, wav...) -> mono 24 kHz wav the model can read."""
    subprocess.run([FFMPEG, "-y", "-v", "error", "-i", str(path), "-ac", "1", "-ar", str(SR), str(out)], check=True)
    return out


def encode_mp3(x, path):
    buf = io.BytesIO()
    with wave.open(buf, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((np.clip(x, -1, 1) * 32767).astype("<i2").tobytes())
    subprocess.run([FFMPEG, "-y", "-v", "error", "-i", "pipe:0", "-c:a", "libmp3lame", "-b:a", "128k", str(path)],
                   input=buf.getvalue(), check=True)


def trim(x):
    """Cut leading/trailing silence, keeping a short natural tail."""
    _, (a, b) = librosa.effects.trim(x, top_db=38)
    a = max(0, a - int(0.04 * SR))
    b = min(len(x), b + int(0.10 * SR))
    return x[a:b]


def spread(script_text, words):
    """Script tokens with times from whisper. Same count: one-to-one; otherwise spread the
    script tokens over the spoken span in proportion to their length."""
    tokens = script_text.split()
    if not words:
        return []
    if len(words) == len(tokens):
        return [(t, w.start, w.end) for t, w in zip(tokens, words)]
    t0, t1 = words[0].start, words[-1].end
    lens = np.array([len(t) + 1 for t in tokens], dtype=float)
    edges = t0 + (t1 - t0) * np.concatenate([[0], np.cumsum(lens) / lens.sum()])
    return [(t, edges[i], edges[i + 1] - 0.02) for i, t in enumerate(tokens)]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ref", action="append", required=True, help="SPEAKER=path to that person's voice sample")
    ap.add_argument("--exaggeration", type=float, default=0.6)
    ap.add_argument("--cfg", type=float, default=0.4)
    ap.add_argument("--temperature", type=float, default=0.8)
    ap.add_argument("--whisper", default="small.en")
    ap.add_argument("ids", nargs="*")
    args = ap.parse_args()

    from chatterbox.tts import ChatterboxTTS
    from faster_whisper import WhisperModel

    CACHE.mkdir(exist_ok=True)
    refs = {}
    for r in args.ref:
        sp, path = r.split("=", 1)
        refs[sp] = str(to_wav(path, CACHE / f"ref_{sp}.wav"))
    model = ChatterboxTTS.from_pretrained(device="cuda")
    asr = WhisperModel(args.whisper, device="cpu", compute_type="int8")
    rng = random.Random(7)

    conds = {}
    for sp, path in refs.items():
        model.prepare_conditionals(path, exaggeration=args.exaggeration)
        conds[sp] = model.conds

    scenes = json.loads((ROOT / "script_v2.json").read_text(encoding="utf-8"))
    for s in scenes:
        if (args.ids and s["id"] not in args.ids) or not s["lines"]:
            continue
        parts, words, t, prev = [], [], 0.0, None
        for i, line in enumerate(s["lines"]):
            model.conds = conds[line["speaker"]]
            best = None
            for attempt in range(TRIES):
                torch.manual_seed(1000 * i + attempt + zlib.crc32(s["id"].encode()) % 997)
                wav = model.generate(line["text"], exaggeration=args.exaggeration, cfg_weight=args.cfg,
                                     temperature=args.temperature)
                x = wav.squeeze(0).numpy()
                if model.sr != SR:
                    x = librosa.resample(x, orig_sr=model.sr, target_sr=SR)
                x = trim(x)
                segs, _ = asr.transcribe(librosa.resample(x.astype(np.float32), orig_sr=SR, target_sr=16000),
                                         language="en", word_timestamps=True, beam_size=5)
                ws = [w for seg in segs for w in seg.words]
                score = match(line["text"], " ".join(w.word for w in ws))
                if best is None or score > best[0]:
                    best = (score, x, ws)
                if score >= GOOD_ENOUGH:
                    break
                print(f"  {s['id']}#{i} take {attempt + 1}: match {score:.2f}, retrying", flush=True)
            score, x, ws = best
            if prev is not None:
                lo, hi = GAP_SWITCH if line["speaker"] != prev else GAP_SAME
                gap = rng.uniform(lo, hi)
                parts.append(np.zeros(int(gap * SR), dtype=np.float32))
                t += gap
            for text, a, b in spread(line["text"], ws):
                words.append({"offset": int((t + a) * 1e7), "duration": int(max(0.05, b - a) * 1e7),
                              "text": text, "speaker": line["speaker"]})
            parts.append(x.astype(np.float32))
            t += len(x) / SR
            prev = line["speaker"]
            if score < GOOD_ENOUGH:
                print(f"  {s['id']}#{i}: kept best take, match {score:.2f} - listen to this one", flush=True)
        x = np.concatenate(parts)
        x *= 0.89 / max(1e-6, np.abs(x).max())
        encode_mp3(x, PUB / f"{s['id']}.mp3")
        (PUB / f"{s['id']}-words.json").write_text(json.dumps(words), encoding="utf-8")
        print(f"VOICE {s['id']:11s} {len(x) / SR:5.1f}s {len(words)} words", flush=True)


if __name__ == "__main__":
    main()
