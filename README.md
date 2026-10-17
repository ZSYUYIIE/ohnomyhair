# Oh No My Hair

2-player local co-op puzzle platformer for the World Cup of Game Development jam
(theme: **Better Together**, bonus **Something's Off**). Godot 4.7, GDScript.

## Open the project
1. Install **Godot 4.7.x standard** (not .NET).
2. Godot Project Manager → **Import** → pick this folder's `project.godot` → **Import & Edit**.

## Controls (shared keyboard)
| | Move | Jump | Down | Attack | Skill |
|---|---|---|---|---|---|
| P1 | A / D | W | S | F | G |
| P2 | ← / → | ↑ | ↓ | . | / |

Edit in Project Settings → Input Map. In code: `Input.is_action_pressed("p1_left")`.

## Repo layout
- `project.godot`, `scenes/`, `icon.svg` — the game
- `.claude/skills`, `.agents/skills`, `skills-lock.json` — AI agent skills (Godot, platformer, combat, camera, web export)
