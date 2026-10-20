"""Glitch-fixed rebuild of videos/Oh_No_My_Hair_Pitch_Final.mp4 with a human narration.

One full recording in (any format FFmpeg reads, e.g. a phone .m4a). The recording is transcribed
locally, aligned to the v1 script, cut into the 18 scenes (fumbled retakes and long pauses removed),
and turned into scene lengths, captions, a narration track and editor/src/final/data.ts.

Run from the repo root:
  pitch/.venv-v3/Scripts/python.exe pitch/final_fix/build.py "C:/Recordings/pitch.m4a"
  pitch/.venv-v3/Scripts/python.exe pitch/final_fix/render.py
"""
import argparse
import difflib
import hashlib
import json
import math
import re
import shutil
import subprocess
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parent
PITCH = ROOT.parent
PUB = PITCH / "editor" / "public"
CACHE = ROOT / "cache"
FINAL = PITCH / "videos" / "Oh_No_My_Hair_Pitch_Final.mp4"
SCRIPT = PITCH / "docs" / "Oh_No_My_Hair_Pitch_Script.txt"
FPS = 30
SR = 48000
LEAD = 0.4  # seconds from scene start to the narration (the fade-in takes 10 frames)
TAIL = 0.85  # breathing room after each scene's narration, as in the original timeline
MAX_PAUSE = 1.2  # longer silences inside a scene are shortened to KEEP_PAUSE
KEEP_PAUSE = 0.6

# Scene starts in Final.mp4 (the frame where the previous scene has faded to the bare background).
FINAL_STARTS = [0, 321, 836, 1297, 1723, 2234, 2710, 3231, 3804, 4200, 4577, 5102, 5608, 6111, 6529, 7092, 7548, 7951]
FINAL_FRAMES = 8290

# kind 'code' scenes render through PitchScene (verified pixel-equal to Final apart from encoding);
# kind 'footage' scenes reuse Final's own frames with the old caption strip covered.
SCENES = [
    {"id": "hook", "kind": "code", "pitch": "hero", "eyebrow": ""},
    {"id": "story", "kind": "code", "pitch": "story", "eyebrow": ""},
    {"id": "twins", "kind": "code", "pitch": "game", "eyebrow": "TWO DIFFERENT ROLES"},
    {"id": "pomp", "kind": "code", "pitch": "game", "eyebrow": "TWO DIFFERENT ROLES"},
    {"id": "sling", "kind": "code", "pitch": "game", "eyebrow": "THE DIFFERENCE IS IN THE COMBINATIONS"},
    {"id": "parry", "kind": "code", "pitch": "game", "eyebrow": "TURN A THREAT INTO A TOOL"},
    {"id": "water", "kind": "code", "pitch": "game", "eyebrow": "A SALON THAT CHANGES THE RULES"},
    {"id": "boss", "kind": "code", "pitch": "game", "eyebrow": "A FINALE THAT REMIXES THE JOURNEY"},
    {"id": "theme", "kind": "footage"},
    {"id": "audience", "kind": "footage"},
    {"id": "market", "kind": "footage"},
    {"id": "prototype", "kind": "code", "pitch": "prototype", "eyebrow": "WHAT EXISTS TODAY"},
    {"id": "budget", "kind": "footage"},
    {"id": "costs", "kind": "footage"},
    {"id": "roadmap", "kind": "footage"},
    {"id": "validation", "kind": "footage"},
    {"id": "team", "kind": "footage"},
    # Not in Final: who does what. Its narration was recorded separately; a takes file supplies it
    # as an audio file, so the automatic path leaves this scene out.
    {"id": "roles", "kind": "code", "pitch": "roles", "eyebrow": "THE CONTRIBUTORS", "extra": True, "title": "Who does what.",
     "text": "Hongshan and Zuyi are both third-year computer science students. Hongshan works on art and coding, and Zuyi works on audio and coding. "
             "We discuss the game design together, and we both do QA through internal playtests."},
    {"id": "end", "kind": "code", "pitch": "end", "eyebrow": ""},
]
FINAL_ORDER = [s["id"] for s in SCENES if not s.get("extra")]

# Gameplay played once, without looping and without the room-exit wipe at the end of each capture
# (Final looped the clips and showed that wipe, which made the picture jump). Pieces are
# (clip, first source frame, end source frame exclusive, normal playback rate).
MEDIA = {
    "twins": [("carry_launch", 0, 291, 0.8)],
    "pomp": [("fresh_cut", 0, 308, 1.0)],
    # Frames 237-285 are both players waiting for the gel to regrow (only the HUD timer moves).
    "sling": [("sling_gel", 0, 237, 0.7), ("sling_gel", 286, 315, 0.7)],
    "parry": [("parry_catch", 270, 885, 1.0)],
    "water": [("water", 0, 479, 1.0)],
    # Final hard-cut the stomp clip over the boss clip; here it dissolves in.
    "boss": [("boss", 0, 299, 1.0), ("stomp", 0, 89, 0.6)],
    # wet_coop cuts to an unrelated shot at frame 371.
    "prototype": [("wet_coop", 0, 371, 1.0)],
}
MIN_SPEED = 0.5  # slowest playback relative to normal before the last frame is held
MAX_SPEED = 1.25
SPEECH_RMS = 0.1
DISSOLVE = 8  # frames


def run(cmd, **kw):
    return subprocess.run(cmd, check=True, **kw)


def probe_seconds(path):
    out = subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)], text=True)
    return float(out.strip())


def load_script():
    lines = [x.strip() for x in SCRIPT.read_text(encoding="utf-8").splitlines() if x.strip()]
    pairs = list(zip(lines[0::2], lines[1::2]))
    original = [s for s in SCENES if not s.get("extra")]
    assert len(pairs) == len(original), f"{len(pairs)} script sections for {len(original)} scenes"
    for s, (title, text) in zip(original, pairs):
        s["title"], s["text"] = title, text
    SCENES[0]["title"] = "Bad hair. Good friends."  # hero subtitle
    return SCENES


def norm(x):
    return re.sub(r"[^a-z0-9]", "", x.lower())


# Names the recogniser should know; a hint, not a constraint.
PROMPT = ("Oh No My Hair, a two-player cooperative puzzle platformer by NPC Union. Twin-Tails, Pompadour, gel curtain, "
          "parry, scissors, sling dash, hair dryers, PICO PARK 2, Ibb and Obb, itch dot io, ChenHongshan333, ZSYUYIIE.")


def transcribe(recording, work, model_name):
    path = work / f"transcript-{model_name}.json"
    if path.exists():
        return json.loads(path.read_text(encoding="utf-8"))
    from faster_whisper import WhisperModel
    model = WhisperModel(model_name, device="cpu", compute_type="int8", download_root=str(PITCH.parent / "build" / "pitch-v4-models"))
    audio = np.frombuffer(subprocess.check_output(["ffmpeg", "-v", "error", "-i", str(recording), "-f", "f32le", "-ar", "16000", "-ac", "1", "-"]), dtype="<f4")
    segments, _ = model.transcribe(audio, language="en", beam_size=5, word_timestamps=True, vad_filter=False, condition_on_previous_text=False, initial_prompt=PROMPT)
    words = [{"text": w.word.strip(), "start": w.start, "end": w.end} for s in segments for w in s.words]
    path.write_text(json.dumps(words, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    return words


def align(scenes, words):
    """Match script tokens to spoken words. Returns, per scene, the script tokens with times and
    which spoken words matched which script token."""
    tokens, ranges = [], []
    for s in scenes:
        a = len(tokens)
        tokens += s["text"].split()
        ranges.append((a, len(tokens)))

    def units(items):
        u, owner = [], []
        for i, text in enumerate(items):
            for part in re.findall(r"[A-Za-z0-9]+(?:'[A-Za-z]+)?", text):
                u.append(norm(part))
                owner.append(i)
        return u, owner

    left, lo = units(tokens)
    right, ro = units([w["text"] for w in words])
    tok_words = {}  # script token -> spoken word indices
    word_units = {}  # spoken word -> matched script sub-word positions
    for block in difflib.SequenceMatcher(None, left, right, autojunk=False).get_matching_blocks():
        for n in range(block.size):
            tok_words.setdefault(lo[block.a + n], set()).add(ro[block.b + n])
            word_units.setdefault(ro[block.b + n], []).append(block.a + n)
    coverage = len(tok_words) / len(tokens)
    if coverage < 0.75:
        raise SystemExit(f"Only {coverage:.0%} of the script matched the recording. Check the file, nothing was changed.")
    out = []
    for s, (a, b) in zip(scenes, ranges):
        hit = [i for i in range(a, b) if i in tok_words]
        if len(hit) < 0.5 * (b - a):
            raise SystemExit(f"Scene '{s['id']}' matched only {len(hit)}/{b - a} words. Nothing was changed.")
        times = {i: (min(words[j]["start"] for j in tok_words[i]), max(words[j]["end"] for j in tok_words[i])) for i in hit}
        timed = []
        for i in range(a, b):
            if i in times:
                st, en = times[i]
            else:  # interpolate between matched neighbours
                l = max((j for j in hit if j < i), default=None)
                r = min((j for j in hit if j > i), default=None)
                if l is None:
                    st = times[r][0] - 0.2 * (r - i); en = st + 0.18
                elif r is None:
                    st = times[l][1] + 0.2 * (i - l - 1); en = st + 0.18
                else:
                    gap = times[r][0] - times[l][1]
                    st = times[l][1] + gap * (i - l - 1) / (r - l - 1)
                    en = times[l][1] + gap * (i - l) / (r - l - 1)
            timed.append({"text": tokens[i], "start": st, "end": max(en, st + 0.05)})
        spoken = {j: (min(word_units[j]), max(word_units[j])) for i in hit for j in tok_words[i]}
        out.append({"tokens": timed, "spoken": spoken, "matched": len(hit) / (b - a)})
    return out, coverage


def units(items):
    """Sub-words of each item (hyphenated words split), with the index of the item they came from."""
    u, owner = [], []
    for i, text in enumerate(items):
        for part in re.findall(r"[A-Za-z0-9]+(?:'[A-Za-z]+)?", text):
            u.append(norm(part))
            owner.append(i)
    return u, owner


def time_tokens(tokens, words):
    """Times for each token of a known text spoken in `words`; unmatched tokens are interpolated."""
    left, lo = units(tokens)
    right, ro = units([w["text"] for w in words])
    hits = {}
    for block in difflib.SequenceMatcher(None, left, right, autojunk=False).get_matching_blocks():
        for n in range(block.size):
            hits.setdefault(lo[block.a + n], set()).add(ro[block.b + n])
    times = {i: (min(words[j]["start"] for j in js), max(words[j]["end"] for j in js)) for i, js in hits.items()}
    hit = sorted(times)
    if not hit:
        raise SystemExit("No words matched inside a take: " + " ".join(tokens[:8]))
    out = []
    for i in range(len(tokens)):
        if i in times:
            st, en = times[i]
        else:
            l = max((j for j in hit if j < i), default=None)
            r = min((j for j in hit if j > i), default=None)
            if l is None:
                st = times[r][0] - 0.2 * (r - i); en = st + 0.18
            elif r is None:
                st = times[l][1] + 0.2 * (i - l - 1); en = st + 0.18
            else:
                gap = times[r][0] - times[l][1]
                st = times[l][1] + gap * (i - l - 1) / (r - l - 1)
                en = times[l][1] + gap * (i - l) / (r - l - 1)
        out.append({"text": tokens[i], "start": st, "end": max(en, st + 0.05)})
    return out, len(hit) / len(tokens)


def shorten_pauses(keep, audio):
    """Split keep-intervals around silences longer than MAX_PAUSE, leaving KEEP_PAUSE. Silence is
    measured on the audio (10 ms windows), since recogniser word times can swallow pauses."""
    removed = []
    hop = SR // 100
    for a, b in keep:
        seg = audio[int(a * SR):int(b * SR)]
        rms = np.sqrt((seg[:len(seg) // hop * hop].reshape(-1, hop) ** 2).mean(axis=1))
        silent = rms < SPEECH_RMS * 0.12
        n = 0
        while n < len(silent):
            if not silent[n]:
                n += 1
                continue
            m = n
            while m < len(silent) and silent[m]:
                m += 1
            gap = (m - n) / 100
            if gap > MAX_PAUSE and n > 0 and m < len(silent):
                mid, half = a + (n + m) / 200, (gap - KEEP_PAUSE) / 2
                removed.append((mid - half, mid + half, f"pause {gap:.1f}s"))
            n = m
    out = []
    for a, b in keep:
        t = a
        for x, y, _ in sorted(removed):
            if a <= x and y <= b:
                out.append((t, x)); t = y
        out.append((t, b))
    return out, removed


def quiet(audio, a, b):
    """True when the recording is near-silent between a and b seconds (a pause, not untranscribed speech)."""
    seg = audio[int(a * SR):int(b * SR)]
    if len(seg) < SR // 20:
        return True
    frames = seg[:len(seg) // 480 * 480].reshape(-1, 480)
    return float(np.sqrt((frames ** 2).mean(axis=1)).max()) < SPEECH_RMS * 0.18


def cut_plan(words, info, prev_end, next_start, audio):
    """Keep-intervals (recording seconds) for one scene: from just before the first script word to
    just after the last, minus retakes and long pauses. A retake is speech inserted between two
    consecutive script words (a restarted sentence); unmatched words that stand in for script words
    (numbers, names the recogniser spells differently) are kept."""
    toks = info["tokens"]
    start = max(prev_end, toks[0]["start"] - 0.12)
    end = min(next_start, toks[-1]["end"] + 0.22)
    spoken = info["spoken"]
    removed = []
    inside = [j for j, w in enumerate(words) if w["end"] > start and w["start"] < end]
    # Retakes: runs of spoken words not matched to this scene's script, between matched words.
    run_ = []
    for j in inside + [None]:
        if j is not None and j not in spoken:
            run_.append(j)
            continue
        if run_:
            before = [k for k in inside if k < run_[0] and k in spoken]
            after = [k for k in inside if k > run_[-1] and k in spoken]
            # No script words skipped between the neighbours: the run is extra speech, not a mis-hearing.
            # One short word is more likely the recogniser echoing the previous word than a retake.
            real = len(run_) >= 2 and words[run_[-1]]["end"] - words[run_[0]]["start"] >= 0.35
            if before and after and real and spoken[after[0]][0] - spoken[before[-1]][1] <= 1 and not quiet(audio, words[run_[0]]["start"], words[run_[-1]]["end"]):
                a, b = words[before[-1]]["end"] + 0.2, words[after[0]]["start"] - 0.25
                if b - a > 0.2:
                    removed.append((a, b, "retake: " + " ".join(words[k]["text"] for k in run_)))
            run_ = []
    # Long pauses between consecutive spoken words.
    for j, k in zip(inside, inside[1:]):
        gap_a, gap_b = words[j]["end"], words[k]["start"]
        mid = (gap_a + gap_b) / 2
        half = (gap_b - gap_a - KEEP_PAUSE) / 2
        if gap_b - gap_a > MAX_PAUSE and not any(a <= gap_a and gap_b <= b for a, b, _ in removed) and quiet(audio, mid - half, mid + half):
            removed.append((mid - half, mid + half, f"pause {gap_b - gap_a:.1f}s"))
    removed.sort()
    keep, t = [], start
    for a, b, _ in removed:
        if a > t:
            keep.append((t, a))
        t = max(t, b)
    keep.append((t, end))
    return keep, removed


def remap(t, keep):
    """Recording time -> time inside the edited scene narration (keep may be out of recording order)."""
    acc, best = 0.0, None
    for a, b in keep:
        dist = max(a - t, t - b, 0)
        if best is None or dist < best[0]:
            best = (dist, acc + min(max(t - a, 0.0), b - a))
        acc += b - a
    return best[1]


def captions(tokens, offset):
    """One caption per sentence; sentences over ten words split into even parts, at a comma when
    one is near. Short sentences ("Carry me.") join the next."""
    sentences, cur = [], []
    for i, w in enumerate(tokens):
        cur.append(w)
        if w["text"].endswith((".", "?", "!", ";", ":")) or i == len(tokens) - 1:
            if sentences and len(sentences[-1]) < 4 and len(sentences[-1]) + len(cur) <= 10:
                sentences[-1] += cur
            else:
                sentences.append(cur)
            cur = []
    groups = []
    for sent in sentences:
        parts = math.ceil(len(sent) / 10)
        start = 0
        for k in range(1, parts):
            ideal = round(len(sent) * k / parts)
            near = [j for j in range(max(start + 3, ideal - 2), min(len(sent) - 3, ideal + 3)) if sent[j - 1]["text"].endswith(",")]
            cut = min(near, key=lambda j: abs(j - ideal)) if near else ideal
            groups.append(sent[start:cut])
            start = cut
        groups.append(sent[start:])
    caps = [[" ".join(x["text"] for x in g), offset + g[0]["start"] - 0.05, offset + g[-1]["end"] + 0.25] for g in groups]
    for a, b in zip(caps, caps[1:]):
        a[2] = min(a[2], b[1])
    return [{"text": t, "startMs": round(a * 1000, 1), "endMs": round(b * 1000, 1), "timestampMs": round(a * 1000, 1), "confidence": None} for t, a, b in caps]


def media_plan(pieces, frames):
    """Lay the pieces end to end at one common speed so they fill the scene once. A single clip
    longer than the scene plays at normal speed and is cut by the scene's fade-out; several pieces
    are sped up (to MAX_SPEED) so the last one is still seen."""
    joins = sum(DISSOLVE for p, q in zip(pieces, pieces[1:]) if p[0] != q[0])
    natural = sum((b - a) / rate for _, a, b, rate in pieces) - joins
    if natural >= frames:
        speed = 1.0 if len(pieces) == 1 else min(MAX_SPEED, natural / frames)
    else:
        speed = max(MIN_SPEED, natural / frames)
    out, t = [], 0.0
    for n, (clip, a, b, rate) in enumerate(pieces):
        r = rate * speed
        # Same clip continuing: butt-join. Different clip: overlap by DISSOLVE frames.
        dissolve = DISSOLVE if n and clip != pieces[n - 1][0] else 0
        t -= dissolve
        start, end = round(t), min(frames, round(t + (b - a) / r))
        if start >= frames:
            break
        out.append({"clip": clip, "from": start, "duration": end - start, "trimBefore": a, "rate": round(r, 4), "fadeIn": dissolve})
        t += (b - a) / r
    last = out[-1]
    held = frames - (last["from"] + last["duration"])
    if held > 0:  # still too short at the slowest speed: hold the final frame
        clip, a, b, _ = pieces[-1]
        out.append({"clip": clip, "from": last["from"] + last["duration"], "duration": held, "trimBefore": b - 1, "rate": 1, "fadeIn": 0, "hold": True})
    return out, speed


def main():
    p = argparse.ArgumentParser()
    p.add_argument("recording", help="the full narration recording (m4a, wav, mp3...)")
    p.add_argument("--check-only", action="store_true", help="align and report, but do not write the timeline")
    p.add_argument("--takes", help="edit list to use (default: takes/<recording hash>.json), e.g. for a re-encoded copy of the same recording")
    p.add_argument("--model", default="base.en", help="faster-whisper model for the transcript (a takes file names its own)")
    args = p.parse_args()
    recording = Path(args.recording).resolve()
    key = hashlib.sha256(recording.read_bytes()).hexdigest()[:12]
    work = CACHE / key
    work.mkdir(parents=True, exist_ok=True)
    scenes = load_script()
    # A takes file (takes/<hash>.json) is a hand-made edit list for one recording: which stretches of
    # the recording each scene uses, and the words actually said there (captions follow them).
    takes_path = Path(args.takes).resolve() if args.takes else ROOT / "takes" / f"{key}.json"
    takes = json.loads(takes_path.read_text(encoding="utf-8")) if takes_path.exists() else None
    words = transcribe(recording, work, takes["model"] if takes else args.model)
    if takes:
        print("Using edit list", takes_path.relative_to(PITCH))
        scenes = [s for s in scenes if s["id"] in takes["scenes"]]
        infos, coverage = [], None
    else:
        scenes = [s for s in scenes if not s.get("extra")]
        infos, coverage = align(scenes, words)

    audio = np.frombuffer(subprocess.check_output(["ffmpeg", "-v", "error", "-i", str(recording), "-f", "f32le", "-ar", str(SR), "-ac", "1", "-"]), dtype="<f4")
    length = len(audio) / SR
    global SPEECH_RMS  # typical loudness of the spoken words, the reference for "quiet"
    SPEECH_RMS = float(np.median([np.sqrt((audio[int(w["start"] * SR):int(w["end"] * SR)] ** 2).mean() + 1e-12) for w in words if w["end"] - w["start"] > 0.1]))
    report = {"recording": str(recording), "sha256_12": key, "script_words_matched": coverage and round(coverage, 3), "scenes": []}
    clock = 0
    pieces_audio = []
    for i, s in enumerate(scenes):
        source = audio
        if takes and "audio" in takes["scenes"][s["id"]]:
            # Narration from a separate file (a line recorded later), matched to the recording's loudness.
            take = takes["scenes"][s["id"]]
            clip_path = ROOT / take["audio"]
            source = np.frombuffer(subprocess.check_output(["ffmpeg", "-v", "error", "-i", str(clip_path), "-f", "f32le", "-ar", str(SR), "-ac", "1", "-"]), dtype="<f4").copy()
            clip_key = hashlib.sha256(clip_path.read_bytes()).hexdigest()[:12]
            clip_dir = CACHE / clip_key
            clip_dir.mkdir(parents=True, exist_ok=True)
            clip_words = transcribe(clip_path, clip_dir, takes["model"])
            level = np.median([np.sqrt((source[int(w["start"] * SR):int(w["end"] * SR)] ** 2).mean() + 1e-12) for w in clip_words if w["end"] - w["start"] > 0.1])
            source *= SPEECH_RMS / level
            # Whole clip from just before the first word to just after the last, unless keep says otherwise.
            keep = [tuple(k) for k in take.get("keep", [(max(0.0, clip_words[0]["start"] - 0.12), min(len(source) / SR, clip_words[-1]["end"] + 0.22))])]
            inside = [w for a, b in keep for w in clip_words if a - 0.05 <= w["start"] < b]
            timed, matched = time_tokens(take.get("text", s["text"]).split(), inside)
            info = {"tokens": timed, "matched": matched}
            keep, removed = shorten_pauses(keep, source)
        elif takes:
            take = takes["scenes"][s["id"]]
            keep = [tuple(k) for k in take["keep"]]
            # Words in edit order (a scene may borrow a sentence from an earlier take).
            inside = [w for a, b in keep for w in words if a - 0.05 <= w["start"] < b]
            timed, matched = time_tokens(take.get("text", s["text"]).split(), inside)
            info = {"tokens": timed, "matched": matched}
            keep, removed = shorten_pauses(keep, audio)
        else:
            info = infos[i]
            prev_end = infos[i - 1]["tokens"][-1]["end"] + 0.05 if i else 0.0
            next_start = infos[i + 1]["tokens"][0]["start"] - 0.05 if i + 1 < len(infos) else length
            if prev_end >= next_start or info["tokens"][0]["start"] < prev_end - 0.3:
                raise SystemExit(f"Scene '{s['id']}' overlaps its neighbour in the recording; were sections read out of order?")
            keep, removed = cut_plan(words, info, prev_end, next_start, audio)
        voice = sum(b - a for a, b in keep)
        frames = math.ceil((LEAD + voice + TAIL) * FPS)
        tokens = [{"text": w["text"], "start": remap(w["start"], keep), "end": remap(w["end"], keep)} for w in info["tokens"]]
        s.update({"from": clock, "frames": frames, "voiceSeconds": round(voice, 3), "captions": captions(tokens, LEAD)})
        if s["kind"] == "footage":
            n = FINAL_ORDER.index(s["id"])
            a, b = FINAL_STARTS[n], FINAL_STARTS[n + 1] if n + 1 < len(FINAL_STARTS) else FINAL_FRAMES
            s["source"] = {"start": a, "end": b}
        if s["id"] in MEDIA:
            s["media"], speed = media_plan(MEDIA[s["id"]], frames)
            s["mediaSpeed"] = round(speed, 3)
        if s["id"] == "story":
            # Change the art when the narration reaches "Then the scissors" and "Escaping".
            idx = [n for n, w in enumerate(tokens) if norm(w["text"]) in ("then", "escaping")][:2]
            if len(idx) == 2:
                s["storyCuts"] = [round((LEAD + tokens[n]["start"]) * FPS) - 3 for n in idx]
        pieces_audio.append((clock / FPS + LEAD, keep, source))
        report["scenes"].append({"id": s["id"], "matched": round(info["matched"], 3), "recording": [round(keep[0][0], 2), round(keep[-1][1], 2)],
                                 "voice_seconds": round(voice, 2), "scene_seconds": round(frames / FPS, 2),
                                 "removed": [{"from": round(a, 2), "to": round(b, 2), "why": why} for a, b, why in removed],
                                 **({"gameplay_speed": s["mediaSpeed"]} if "mediaSpeed" in s else {})})
        clock += frames
    report["film_seconds"] = round(clock / FPS, 2)
    (work / "alignment_report.json").write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print((f"Matched {coverage:.1%} of the script; " if coverage else "") + f"film {clock / FPS:.1f} s; report {work / 'alignment_report.json'}")
    for r in report["scenes"]:
        extra = f"  gameplay x{r['gameplay_speed']}" if "gameplay_speed" in r else ""
        print(f"  {r['id']:<10} voice {r['voice_seconds']:6.2f}s  scene {r['scene_seconds']:6.2f}s  matched {r['matched']:.0%}{extra}")
        for c in r["removed"]:
            print(f"      cut {c['from']:.2f}-{c['to']:.2f}s  {c['why']}")
    if args.check_only:
        return

    # Narration track: each scene's kept audio with 10 ms fades at every cut, placed at its scene.
    track = np.zeros(int((clock / FPS + 1) * SR), dtype=np.float32)
    fade = int(0.01 * SR)
    for at, keep, source in pieces_audio:
        pos = int(round(at * SR))
        for a, b in keep:
            seg = source[int(a * SR):int(b * SR)].copy()
            n = min(fade, len(seg) // 2)
            if n:
                seg[:n] *= np.linspace(0, 1, n, dtype=np.float32)
                seg[-n:] *= np.linspace(1, 0, n, dtype=np.float32)
            track[pos:pos + len(seg)] += seg
            pos += len(seg)
    track = track[:int(clock / FPS * SR)]
    import wave
    with wave.open(str(CACHE / "narration.wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((np.clip(track, -1, 1) * 32767).astype("<i2").tobytes())

    # Subtitles for upload platforms.
    def stamp(t):
        ms = round(t * 1000); h, ms = divmod(ms, 3600000); m, ms = divmod(ms, 60000); sec, ms = divmod(ms, 1000)
        return f"{h:02}:{m:02}:{sec:02},{ms:03}"
    srt = [(s["from"] / FPS + c["startMs"] / 1000, s["from"] / FPS + c["endMs"] / 1000, c["text"]) for s in scenes for c in s["captions"]]
    (CACHE / "captions.srt").write_text("\n\n".join(f"{i + 1}\n{stamp(a)} --> {stamp(b)}\n{t}" for i, (a, b, t) in enumerate(srt)) + "\n", encoding="utf-8")

    # Final.mp4 is the source for the footage scenes; the copy in public/ is git-ignored.
    (PUB / "final").mkdir(exist_ok=True)
    src = PUB / "final" / "source.mp4"
    if not src.exists() or src.stat().st_size != FINAL.stat().st_size:
        shutil.copy2(FINAL, src)
    data = {"fps": FPS, "frames": clock, "scenes": [{k: s[k] for k in ("id", "kind", "pitch", "title", "eyebrow", "from", "frames", "captions", "source", "media", "storyCuts") if k in s} for s in scenes]}
    (PITCH / "editor" / "src" / "final" / "data.ts").write_text("// Generated by pitch/final_fix/build.py\nexport const DATA = " + json.dumps(data) + " as const;\n", encoding="utf-8")
    shutil.copy2(work / "alignment_report.json", CACHE / "alignment_report.json")
    print("Wrote editor/src/final/data.ts, cache/narration.wav and cache/captions.srt. Next: render.py")


if __name__ == "__main__":
    main()
