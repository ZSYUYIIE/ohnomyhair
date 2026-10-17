# Oh No My Hair

2-player local co-op puzzle platformer for the World Cup of Game Development jam
(theme: **Better Together**, bonus **Something's Off**). Godot 4.7, GDScript.

## Open the project
1. Install **Godot 4.7.x standard** (not .NET).
2. Godot Project Manager → **Import** → pick this folder's `project.godot` → **Import & Edit**.

## Controls (shared keyboard)
| | Move | Jump | Skill | Attack |
|---|---|---|---|---|
| P1 Twin Tails | A / D | W | F: hold to glide, pull levers | G: hair whip (stun) |
| P2 Pompadour | ← / → | ↑ | K: dash, or launch P1 standing on your head | L: parry scissors |

R restarts the level.

Edit in Project Settings → Input Map. In code: `Input.is_action_pressed("p1_left")`.

## Run the tests
```
godot --headless --path . res://tests/test_level_02.tscn
```
Exit code 0 means Level 2's intended solution still works.

## Repo layout
- `project.godot`, `autoload/`, `scenes/`, `icon.svg` — the game (Level 2 prototype is the main scene)
- `docs/levels/` — level designs; `scenes/levels/level_02.gd` builds its map from the same ASCII grid
- `tests/` — headless playthrough tests
- `.claude/skills`, `.agents/skills`, `skills-lock.json` — AI agent skills (Godot, platformer, combat, camera, web export)
