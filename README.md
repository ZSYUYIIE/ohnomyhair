# Oh No My Hair

2-player local co-op puzzle platformer for the World Cup of Game Development jam
(theme: **Better Together**, bonus **Something's Off**). Godot 4.7, GDScript, 1280x720.

## Open the project
1. Install **Godot 4.7.x standard** (not .NET).
2. Godot Project Manager → **Import** → pick this folder's `project.godot` → **Import & Edit**.
3. F5 opens the main menu (level cards unlock as you clear levels; best time and fewest deaths
   are saved in `user://progress.cfg`). To play one level directly: open `scenes/levels/level_0N.tscn` and press F6.

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

### Four-haircut expansion

Choose **Style Lab** on the title screen to try Afro and Long Straight Hair in three new
rooms. At a gold-marked styling chair, bring both friends nearby and press **S / Down**
to choose styles, heal and save a checkpoint for the current room/run.

- **Afro:** hold skill to charge, release to bounce a rider. Pompadour holds skill on top
  as Afro releases for a **cannonball** that breaks reinforced orange gel. Hold attack for
  a short shield or to catch a parried scissor; release to return it.
- **Long Straight:** hold skill on a ledge to lower a rope; your friend holds jump to climb
  and moves sideways to release. In the air, skill hooks a gold ring. Attack lassos bots
  or levers.
- Wet Afro hair cannot spring or shield. Tony's damaging scissors change your haircut;
  blocking prevents it. Watch the portrait and skill hints.

Style Lab does not unlock campaign chapters. Design details and scope:
[`docs/design/four_haircut_expansion.md`](docs/design/four_haircut_expansion.md).

In the campaign each chapter has one pair: Twin-Tails + Pompadour (chapters 1-3), **Afro +
Pompadour** (4, Perm Day), **Twin-Tails + Long Straight** (5, Extensions), and the finale's
arena lets you pick any two different haircuts. A room's chair only offers the haircuts that
room was built for, and `tests/test_gates.gd` checks every allowed pair can get through.
How and why: [`docs/design/roster_and_chapters.md`](docs/design/roster_and_chapters.md);
every room's obstacles: [`docs/levels/gate_graph.md`](docs/levels/gate_graph.md)
(regenerate with `godot --headless --path . --script res://tools/gate_graph.gd`).

### Automated checks
Each test plays through a level with simulated input; exit code 0 = pass.
`test_combos.gd` checks each hair combo (and that the solo shortcut fails) in a bare arena.
```
godot --headless --path . --script res://tests/test_menu.gd
godot --headless --fixed-fps 60 --path . --script res://tests/test_combos.gd
godot --headless --fixed-fps 60 --path . --script res://tests/test_level_01.gd
godot --headless --fixed-fps 60 --path . --script res://tests/test_level_02.gd
godot --headless --fixed-fps 60 --path . --script res://tests/test_level_03.gd
godot --headless --fixed-fps 60 --path . --script res://tests/test_level_04.gd
godot --headless --fixed-fps 60 --path . --script res://tests/test_level_05.gd
godot --headless --fixed-fps 60 --path . --script res://tests/test_level_06.gd
godot --headless --path . --script res://tests/test_gates.gd
godot --headless --fixed-fps 60 --path . --script res://tests/test_haircuts.gd
godot --headless --fixed-fps 60 --path . --script res://tests/test_style_lab.gd
godot --headless --fixed-fps 60 --path . --script res://tests/test_checkpoints.gd
godot --headless --fixed-fps 60 --path . --script res://tests/test_boss_pairs.gd
```
On a fresh checkout run `godot --headless --path . --import` once first.

## Repo layout
- `scenes/player/` — the shared Player and the four haircuts (`abilities/`)
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
