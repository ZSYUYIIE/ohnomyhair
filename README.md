# Oh No My Hair

2-player local co-op puzzle platformer for the World Cup of Game Development jam
(theme: **Better Together**, bonus **Something's Off**). Godot 4.7, GDScript, 1280x720.

## Open the project
1. Install **Godot 4.7.x standard** (not .NET).
2. Godot Project Manager → **Import** → pick this folder's `project.godot` → **Import & Edit**.
3. F5 opens the main menu (level cards unlock as you clear levels; best time and fewest deaths
   are saved in `user://progress.cfg`). To play one level directly: open `scenes/levels/level_0N.tscn` and press F6.

The illustrated title uses **Start Game → Salon Map → Play**. Select an unlocked stop;
the final stop stays a mystery until cleared. A new save plays the supplied 39-second
opening before the first level; any key, mouse click or controller button skips it.
**About** opens team credits, controls and story help.
UI art sources, licenses and integration details: [poster_ui.md](docs/art/poster_ui.md).

From a terminal (`--room=N` starts in room N of that level):
```
godot --path . res://scenes/levels/level_01.tscn -- --room=3
```

## Controls (shared keyboard)
| | Move | Jump | Skill | Attack |
|---|---|---|---|---|
| P1 Twin Tails | A / D | W | G: hold to glide; grab P2 to carry them; pull levers | F: hair whip (stun) |
| P2 Pompadour | ← / → | ↑ | K: dash (smash gel walls), or launch P1 standing on your head | L: parry scissors |

### Hair combos (both friends act at once)
| Combo | Twin Tails | Pompadour | Effect |
|---|---|---|---|
| Carry | hold skill next to P2 (beside you, not on your head), glide | (hangs; can still parry) | fly over pits together |
| Launch | stand on P2's head | skill | rider rises ~9 tiles |
| **Sling Dash** | carry P2 through the air | skill while hanging | flung 7 tiles flat, through gel walls |
| **Hair Catch** | hold skill: open pigtails catch a blue scissor; let go to toss it | parry first (scissor turns blue) | scissor shoots straight up, golden, rings bells |
| **Hair-copter** | glide in a hair dryer's warm air | stand on her head | both rise at full speed (a carry rises too, at about half) |

Salon hazards: **hair dryers** lift a gliding twin-tails (and a friend she carries, slower) and dry
you; **shampoo showers** soak you for 4 s (wet twin-tails can't glide, wet pompadour can't smash
gel; a drop-and-ring meter shows the hair drying); a **growth tonic** grows 1 HP of hair back.
Pompadour gets one dash per jump in the air; landing recharges it.
Hot flat irons cycle cold -> warning ("!") -> red-hot; touching a hot one costs a heart and throws
you clear. The last level ends with **Rush Hour** (three waves of robots dropping from ceiling
vents, each adding a threat) and a three-phase barber-bot boss with a boss bar.
Hair is the health bar: every hit snips a puff of hair off (hearts in the HUD); a soaked friend
turns a washed-out blue and drips.

Design notes: `docs/design/refinement.md`.

While carried, press down to let go. Hold down to drop through a one-way platform.
**Esc** pauses (Resume / Restart room / Main menu). **R** restarts the current room - also from the
death popup and the pause menu. Clearing a level shows its time and deaths in a banner and goes
straight on to the next level; the last level ends on a results screen.
If either friend dies, a popup offers **Restart room** or **Main menu**. Restarting rebuilds the
whole room - enemies, bells, doors, gel and levers reset - while the level's time and death count
carry on. The bottom bar shows each friend's haircut, hearts and keys, plus level, room, time and deaths.
Skill/attack follow the **haircut**, not the player: if hair gets swapped, so do the powers.

Edit in Project Settings → Input Map. In code: `player.pressed("skill")` / `Input.is_action_pressed("p1_left")`.

## Run the tests

### The escape story

Two friends arrive at closing time for a haircut. The barber leaves them with his robot
assistant. One snip too many reveals their hair powers; the robot locks the front door.
Pompadour protects Twin-Tails, she spots the service route, and they choose to escape together.

The campaign follows the same two friends through **Fresh Cut → Return to Sender →
Wash & Blow-Dry → The Assistant**. The finale keeps its internal `level_06.tscn` path and
stable save ID, but is chapter 4 in the game. Chairs and damaging boss scissors can swap
their two familiar haircuts; both players must reach each exit.

**Perm Day, Extensions and Style Lab are retired.** Their source art, abilities, scenes and
tests are preserved under [`archive/four_haircut_prototype`](archive/four_haircut_prototype/README.md),
excluded from Godot by `.gdignore`. The playable roster and portraits use only the original
Twin-Tails and Pompadour artwork. Story and visual direction:
[`docs/design/story_escape.md`](docs/design/story_escape.md).

At a gold-marked chair, bring both friends nearby and press **S / Down** to swap or keep
roles, heal, dry off and save the current room's checkpoint.

### Automated checks
Each test plays through a level with simulated input; exit code 0 = pass.
`test_combos.gd` checks each hair combo (and that the solo shortcut fails) in a bare arena.
```
godot --headless --path . --script res://tests/test_menu.gd
godot --headless --fixed-fps 60 --path . --script res://tests/test_opening.gd
godot --headless --fixed-fps 60 --path . --script res://tests/test_combos.gd
godot --headless --fixed-fps 60 --path . --script res://tests/test_level_01.gd
godot --headless --fixed-fps 60 --path . --script res://tests/test_level_02.gd
godot --headless --fixed-fps 60 --path . --script res://tests/test_level_03.gd
godot --headless --fixed-fps 60 --path . --script res://tests/test_level_06.gd
godot --headless --path . --script res://tests/test_gates.gd
godot --headless --fixed-fps 60 --path . --script res://tests/test_checkpoints.gd
godot --headless --fixed-fps 60 --path . --script res://tests/test_boss_pairs.gd
godot --headless --fixed-fps 60 --path . --script res://tests/test_story_roster.gd
```
On a fresh checkout run `godot --headless --path . --import` once first.

## Repo layout
- `scenes/player/` — the shared Player and the two story haircuts (`abilities/`)
- `scenes/props/`, `scenes/enemies/` — barber-shop props and enemies: chair-pump levers, salon
  counters, regrowing hair-gel, dye basins, hot flat irons, service bells, staff doors, scissor
  dispensers, clipper bots, the barber bot
- `scenes/systems/salon_decor.gd` — background mirrors, lamps and barber poles for each room
- `scenes/systems/progress.gd` — level list, unlocks and best times
- `scenes/ui/` — main menu, bottom-bar HUD, death / pause / results menu, shared UI theme
- `scenes/systems/` — `Level` (rooms, respawn, room-to-room camera) and `Room`; `WaveArena` (robot waves through ceiling vents)
- `scenes/levels/` — generated level scenes
- `tools/` — `build_level_0N.gd` generate the level scenes (rerunning overwrites them),
  `make_greybox_tiles.gd` paints the salon tile atlas,
  `measure_metrics.gd` prints jump/glide/carry/launch reach for sizing gaps
- `assets/art/` — hand-drawn art: character animation strips + SpriteFrames, L1 tiles, room walls
  and prop textures. Style, asset list and how to rebuild them: `docs/art/l1_art_direction.md`
- `art_src/` — source character sheets (ignored by Godot); `tools/art/*.py` turn them and the L1
  world art into `assets/art/` (Python 3 + Pillow), `tools/build_character_frames.gd` makes the SpriteFrames
- `docs/levels/`, `docs/design/`, `docs/art/` — level design docs, the mechanics refinement notes and the art direction
- `tests/` — headless playthrough tests
- `.claude/skills`, `.agents/skills`, `skills-lock.json` — AI agent skills (Godot, platformer, combat, camera, web export)
