# Oh No My Hair

2-player local co-op puzzle platformer for the World Cup of Game Development jam
(theme: **Better Together**, bonus **Something's Off**). Godot 4.7, GDScript, 1280x720.

## Open the project
1. Install **Godot 4.7.x standard** (not .NET).
2. Godot Project Manager → **Import** → pick this folder's `project.godot` → **Import & Edit**.
3. F5 starts at Level 1. To play one level: open `scenes/levels/level_0N.tscn` and press F6.

From a terminal (`--room=N` starts in room N of that level):
```
godot --path . res://scenes/levels/level_01.tscn -- --room=3
```

## Controls (shared keyboard)
| | Move | Jump | Skill | Attack |
|---|---|---|---|---|
| P1 Twin Tails | A / D | W | G: hold to glide; grab P2 to carry them; pull levers | F: hair whip (stun) |
| P2 Pompadour | ← / → | ↑ | K: dash (smash gel walls), or launch P1 standing on your head | L: parry scissors |

While carried, press down to let go. R restarts the current room.
Skill/attack follow the **haircut**, not the player: if hair gets swapped, so do the powers.

Edit in Project Settings → Input Map. In code: `player.pressed("skill")` / `Input.is_action_pressed("p1_left")`.

## Run the tests
Each test plays through a level with simulated input; exit code 0 = pass.
```
godot --headless --fixed-fps 60 --path . --script res://tests/test_level_01.gd
godot --headless --fixed-fps 60 --path . --script res://tests/test_level_02.gd
```
On a fresh checkout run `godot --headless --path . --import` once first.

## Repo layout
- `scenes/player/` — the shared Player and the two haircuts (`abilities/`)
- `scenes/props/`, `scenes/enemies/` — levers, blocks, gel walls, hazards, doors, scissors, bots
- `scenes/systems/` — `Level` (rooms, respawn, room-to-room camera) and `Room`
- `scenes/levels/` — generated level scenes
- `tools/` — `build_level_0N.gd` generate the level scenes (rerunning overwrites them),
  `measure_metrics.gd` prints jump/glide/carry/launch reach for sizing gaps
- `docs/levels/` — level design docs
- `tests/` — headless playthrough tests
- `.claude/skills`, `.agents/skills`, `skills-lock.json` — AI agent skills (Godot, platformer, combat, camera, web export)
