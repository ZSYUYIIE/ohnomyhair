"""Locate actual captured SFX against original game WAVs (normalized correlation)."""
import json
from pathlib import Path
import subprocess
import numpy as np

ROOT = Path(__file__).resolve().parent
PROJECT = ROOT.parent.parent
SR = 8000


def decode(path):
    return np.frombuffer(subprocess.check_output(["ffmpeg", "-v", "error", "-i", str(path), "-f", "f32le", "-ac", "1", "-ar", str(SR), "-"]), dtype="<f4").astype(float)


def locate(audio, template, maximum=6):
    found = []
    fft_size = 1 << (len(audio) + len(template) - 1).bit_length()
    spectrum = np.fft.rfft(audio, fft_size)
    energy = np.r_[0.0, np.cumsum(audio * audio)]
    score = np.zeros(len(audio))
    for rate in np.linspace(.94, 1.06, 13):
        source = np.arange(0, len(template)-1, rate)
        temp = np.interp(source, np.arange(len(template)), template)
        count = len(audio)-len(temp)+1
        corr = np.fft.irfft(spectrum * np.conj(np.fft.rfft(temp, fft_size)), fft_size)[:count]
        denom = np.sqrt(np.maximum((energy[len(temp):]-energy[:-len(temp)]) * np.sum(temp * temp), 1e-12))
        score[:count] = np.maximum(score[:count], corr / denom)
    for _ in range(maximum):
        idx = int(np.argmax(score))
        confidence = float(score[idx])
        if confidence < .70:
            break
        found.append({"seconds": round(idx/SR, 4), "correlation": round(confidence, 4)})
        score[max(0,idx-SR//3):idx+SR//3] = 0
    return sorted(found, key=lambda x:x["seconds"])


def main():
    result = {}
    for clip, events in {"parry":["parry","catch","toss","bell"], "sling":["grab","sling","gel_smash"], "boss":["parry","boss_daze","launch","boss_stomp"], "swap":["swap"]}.items():
        path = PROJECT / f"pitch/editor/public/v3/{clip}.mp4"
        if not path.exists():
            continue
        audio = decode(path)
        result[clip] = {name:locate(audio,decode(PROJECT/f"assets/audio/sfx/{name}.wav")) for name in events}
    (ROOT / "captured_audio_cues.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
