"""Difficulty report: how hard each room is, from three cheap sources (no hand testing).

1. Margin table - every gap/height vs. the move's live-measured reach (margins.gd).
2. Sloppy-player sweep - each level's bot playthrough rerun SEEDS times with a person's
   reaction delay, aim and hold-time noise (tests/play_bot.gd, SLOPPY=1). How often each
   step fails says how forgiving its timing is.
3. Play log - deaths and room times written by the game itself (Telemetry), from real
   sessions in user://telemetry and from the sweep's bots; death heatmaps (heatmap.gd).

Writes docs/difficulty/report.md and docs/difficulty/heatmaps/*.png.
Run: python -I tools/difficulty/report.py [--seeds 8] [--jobs 4] [--skip-sweep]
Godot: $GODOT, else the jam's default install path below.
"""
import argparse
import json
import os
import re
import shutil
import statistics
import subprocess
import sys
from collections import Counter, defaultdict
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "difficulty"
DEFAULT_GODOT = r"C:\Users\drdot\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
USER_DIR = Path(os.environ.get("APPDATA", "")) / "Godot" / "app_userdata" / "Oh No My Hair"
LEVEL_TESTS = ["test_level_01", "test_level_02", "test_level_03", "test_level_04", "test_level_05", "test_level_06"]
ANSI = re.compile(r"\x1b\[[0-9;]*m")


def godot() -> str:
    return os.environ.get("GODOT", DEFAULT_GODOT)


def run_godot(args, env_extra=None, timeout=900):
    env = dict(os.environ)
    env.update(env_extra or {})
    proc = subprocess.run([godot(), "--path", str(ROOT)] + args, capture_output=True, text=True,
                          encoding="utf-8", errors="replace", env=env, timeout=timeout)
    return ANSI.sub("", proc.stdout + proc.stderr)


# --- 1. margins ---------------------------------------------------------------------

def margins():
    target = USER_DIR / "difficulty" / "margins.json"
    run_godot(["--headless", "--fixed-fps", "60", "--script", "res://tools/difficulty/margins.gd"],
              {"OUT": str(target)})
    return json.loads(target.read_text(encoding="utf-8"))


def rate(slack):
    if slack < 0:
        return "impossible"
    if slack < 1.0:
        return "tight"
    if slack < 2.0:
        return "fair"
    return "roomy"


# --- 2. sloppy sweep ----------------------------------------------------------------

def one_run(test, seed):
    out = run_godot(["--headless", "--fixed-fps", "60", "--script", f"res://tests/{test}.gd"],
                    {"SLOPPY": "1", "SEED": str(seed)})
    m = re.search(r"Results: (\d+) passed, (\d+) failed", out)
    fails = re.findall(r"^\s+FAIL (.+?)(?:\s{3}p1=|$)", out, re.M)
    return {"test": test, "seed": seed, "passed": int(m.group(1)) if m else 0,
            "failed": int(m.group(2)) if m else -1, "first_fail": fails[0].strip() if fails else ""}


def sweep(seeds, jobs):
    bots = USER_DIR / "telemetry_bots"
    if bots.exists():
        for f in bots.glob("*.jsonl"):   # the sweep's own previous logs only
            f.unlink()
    runs = [(t, s) for t in LEVEL_TESTS for s in range(1, seeds + 1)]
    with ThreadPoolExecutor(max_workers=jobs) as pool:
        results = list(pool.map(lambda r: one_run(*r), runs))
    return results


# --- 3. play log --------------------------------------------------------------------

def read_logs():
    events = []
    for folder in ("telemetry", "telemetry_bots"):
        for f in sorted((USER_DIR / folder).glob("*.jsonl")) if (USER_DIR / folder).exists() else []:
            for line in f.read_text(encoding="utf-8").splitlines():
                if line.strip():
                    e = json.loads(line)
                    e["session"] = f.stem
                    events.append(e)
    return events


def summarise(events):
    rooms = defaultdict(lambda: {"title": "", "starts": 0, "clears": 0, "deaths": 0,
                                 "causes": Counter(), "times": [], "sessions": set()})
    for e in events:
        key = (e["source"], e["level"], e["room"])
        r = rooms[key]
        r["title"] = e.get("room_title", "")
        r["sessions"].add(e["session"])
        if e["kind"] == "room_start":
            r["starts"] += 1
        elif e["kind"] == "room_clear":
            r["clears"] += 1
        elif e["kind"] == "death":
            r["deaths"] += 1
            r["causes"][e.get("cause", "?")] += 1
    # Time in a room = from its first start to its clear, per session (restarts included).
    first = {}
    for e in events:
        key = (e["source"], e["level"], e["room"], e["session"])
        if e["kind"] == "room_start" and key not in first:
            first[key] = e["level_time"]
        if e["kind"] == "room_clear" and key in first:
            rooms[key[:3]]["times"].append(e["level_time"] - first[key])
    return rooms


# --- report -------------------------------------------------------------------------

def write_report(margin_data, sweep_results, rooms, heatmaps):
    md = ["# Difficulty report (generated)", "",
          "> `python -I tools/difficulty/report.py` rebuilds this page; see the bottom for how to read it.", ""]

    md += ["## 1. Margins: how much room to spare", "",
           "Every gap and height a room asks for, against the move's reach measured just now in an",
           "empty arena (tiles). *tight* < 1 tile, *fair* < 2, *roomy* otherwise.", "",
           "| Level | Room | Obstacle | Move | Needs | Reaches | Spare | |", "|---|---|---|---|---|---|---|---|"]
    for m in margin_data["margins"]:
        md.append(f"| {m['level']} | {m['room']} | {m['gate']} | {m['verb']} | {m['need']:g} | {m['have']:.1f} | {m['slack']:+.1f} | {rate(m['slack'])} |")
    md += ["", "Measured reach: " + ", ".join(f"`{k}` {v}" for k, v in sorted(margin_data["measured"].items())), ""]

    if sweep_results:
        md += ["## 2. Sloppy players: does it survive a person's timing?", "",
               "Each level's playthrough bot, rerun with 130-330 ms reactions, aim off by up to",
               "6 px and button holds 25 % too long or short. Clean = every check passed.", "",
               "| Level | Clean runs | Most common first failure |", "|---|---|---|"]
        by_test = defaultdict(list)
        for r in sweep_results:
            by_test[r["test"]].append(r)
        for test in LEVEL_TESTS:
            runs = by_test.get(test, [])
            if not runs:
                continue
            clean = sum(1 for r in runs if r["failed"] == 0)
            firsts = Counter(r["first_fail"] for r in runs if r["first_fail"])
            top = "; ".join(f"{label} ({n}x)" for label, n in firsts.most_common(3)) or "-"
            md.append(f"| {test.replace('test_', '')} | {clean}/{len(runs)} | {top} |")
        md.append("")

    md += ["## 3. Play log: where people (and sloppy bots) die, and how long rooms take", ""]
    if not rooms:
        md += ["No play logged yet. Every game now writes its log by itself; play a level and rerun.", ""]
    else:
        md += ["| Source | Level | Room | Sessions | Starts | Clears | Deaths | Median time (s) | Top causes |",
               "|---|---|---|---|---|---|---|---|---|"]
        for (source, level, room), r in sorted(rooms.items()):
            t = f"{statistics.median(r['times']):.1f}" if r["times"] else "-"
            causes = ", ".join(f"{c} {n}" for c, n in r["causes"].most_common(3)) or "-"
            md.append(f"| {source} | {level} | {r['title']} | {len(r['sessions'])} | {r['starts']} | {r['clears']} | {r['deaths']} | {t} | {causes} |")
        md.append("")
    if heatmaps:
        md += ["### Death heatmaps", "", "Red dots: people. Orange dots: sloppy bots.", ""]
        for h in heatmaps:
            md += [f"**{h.stem}**", "", f"![{h.stem}](heatmaps/{h.name})", ""]

    md += ["## How to read it", "",
           "- **Margins** catch layout that is too tight (or impossible) for a move, with no play at all.",
           "- **Sloppy runs** catch steps that need near-perfect timing: a step that fails for a",
           "  bot with human reaction times will fail for a lot of people. A failure can also be the",
           "  bot's own script being brittle; the first-failure label says which step to look at.",
           "- **The play log** is the only part that says anything about people. It records by",
           "  itself on every playthrough (local files only), so short sessions from friends add up.",
           "- None of this measures *fun*. Use it to find the rooms worth watching someone play.", ""]
    (OUT / "report.md").write_text("\n".join(md), encoding="utf-8", newline="\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--seeds", type=int, default=8)
    ap.add_argument("--jobs", type=int, default=4)
    ap.add_argument("--skip-sweep", action="store_true")
    args = ap.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)

    print("margins...", flush=True)
    margin_data = margins()
    sweep_results = []
    if not args.skip_sweep:
        print(f"sloppy sweep: {len(LEVEL_TESTS)} levels x {args.seeds} seeds, {args.jobs} at a time...", flush=True)
        sweep_results = sweep(args.seeds, args.jobs)
        (OUT / "sweep.json").write_text(json.dumps(sweep_results, indent=1), encoding="utf-8")
    print("play log + heatmaps...", flush=True)
    rooms = summarise(read_logs())
    heat_dir = OUT / "heatmaps"
    if heat_dir.exists():
        shutil.rmtree(heat_dir)
    heat_dir.mkdir()
    run_godot(["--script", "res://tools/difficulty/heatmap.gd"], {"OUT_DIR": str(heat_dir)})
    heatmaps = sorted(heat_dir.glob("*.png"))
    write_report(margin_data, sweep_results, rooms, heatmaps)
    print(f"wrote {OUT / 'report.md'} ({len(heatmaps)} heatmaps)")


if __name__ == "__main__":
    sys.exit(main())
