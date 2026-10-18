# Difficulty report: test difficulty without hand-playing every room

Hand playtesting is still the only way to judge *fun*. These tools find the rooms worth
watching someone play, in about a minute and without anyone at the keyboard.

```
python -I tools/difficulty/report.py              # margins + 8-seed sloppy sweep + play log
python -I tools/difficulty/report.py --seeds 20   # more seeds, steadier percentages
python -I tools/difficulty/report.py --skip-sweep # just margins + the play log so far
```

Output: [report.md](report.md) and `heatmaps/`. Godot comes from `$GODOT` (default: the
jam machine's install path in `report.py`).

| Part | Answers | How | Code |
|---|---|---|---|
| **Margins** | Is a gap or height too tight (or impossible) for the move meant to clear it? | Measures each move's reach live in an empty arena, then compares it with every gate's size | `tools/difficulty/margins.gd`, gate sizes in `rb.gate(name, verbs, {"gap": w, "drop": d})` / `{"rise": h}` |
| **Sloppy sweep** | Does a step need frame-perfect timing? | Reruns every level's playthrough bot with person-like noise: 130-330 ms reaction to outside cues (a shower stopping, an enemy arriving), aim off by up to 6 px, button holds 25 % long or short. Many seeds, in parallel; about 3 s per run | `tests/play_bot.gd` (`SLOPPY=1 SEED=n`) |
| **Play log** | Where do people die, and how long does each room take? | The game logs room starts, clears and deaths (position, haircut, likely cause) to local files on every playthrough | `scenes/systems/telemetry.gd` |
| **Heatmaps** | Where exactly? | Renders each room and marks the deaths: red = people, orange = sloppy bots | `tools/difficulty/heatmap.gd` |

## Reading it

- A **tight** margin plus deaths in the play log at the same obstacle means you should widen it.
- A step that often fails in the **sloppy sweep** needs a bigger timing window, an earlier
  warning, or a checkpoint. A failure can also be the bot's own script being brittle: look at
  the first-failure label before changing the level.
- **Room times** from people show the pacing curve; compare it with the intended sawtooth in
  the level docs.
- Real sessions log by themselves (`%APPDATA%/Godot/app_userdata/Oh No My Hair/telemetry/`),
  so short sessions from friends add up. Nothing is sent anywhere. Bot runs log to
  `telemetry_bots/` and never mix with people's.
