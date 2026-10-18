# Difficulty report (generated)

> `python -I tools/difficulty/report.py` rebuilds this page; see the bottom for how to read it.

## 1. Margins: how much room to spare

Every gap and height a room asks for, against the move's reach measured just now in an
empty arena (tiles). *tight* < 1 tile, *fair* < 2, *roomy* otherwise.

| Level | Room | Obstacle | Move | Needs | Reaches | Spare | |
|---|---|---|---|---|---|---|---|
| level_01 | 1 - Mirror, Mirror | 10-wide pit to the lever | glide | 10 | 12.2 | +2.2 | roomy |
| level_01 | 2 - The Washing Basin | 8-wide dye pool, both friends | carry | 8 | 11.2 | +3.2 | roomy |
| level_01 | 2 - The Washing Basin | 6-up cliff | launch | 6 | 9.1 | +3.1 | roomy |
| level_03 | 2 - Shampoo Station | 17-wide dye pool from 9 up, both friends | carry | 17 | 20.1 | +3.1 | roomy |
| level_03 | 3 - Rinse & Repeat | 18-wide dye pool from 12 up under a shower, both friends | carry | 18 | 23.9 | +5.9 | roomy |
| level_04 | 1 - The Perm Rollers | Roller shelf 11 up | spring | 11 | 11.7 | +0.7 | tight |
| level_05 | 1 - Extension Bar | Friend up the bar | rope | 9 | 10.0 | +1.0 | fair |
| level_05 | 2 - The Up-Do | 21-wide dye pool from 13 up, both friends | carry | 21 | 25.2 | +4.2 | roomy |
| level_05 | 3 - Tangles | Friend up the ledge | rope | 9 | 10.0 | +1.0 | fair |
| level_05 | 3 - Tangles | 18-wide dye pool from 9 up, both friends | carry | 18 | 20.1 | +2.1 | roomy |
| level_05 | 3 - Tangles | Gate lever 5 up | lasso_lever | 5 | 6.2 | +1.2 | fair |
| level_06 | 1 - Closing Time | 9-wide dye pool, both friends | carry | 9 | 11.2 | +2.2 | roomy |
| level_06 | 2 - The Chair | 6-up cliff | launch | 6 | 9.1 | +3.1 | roomy |
| level_06 | 4 - The Barber Bot | Corner ledge 7 up, above the knob | launch | 7 | 9.1 | +2.1 | roomy |
| level_06 | 4 - The Barber Bot | Corner ledge 7 up, above the knob | spring | 7 | 11.7 | +4.7 | roomy |
| level_06 | 4 - The Barber Bot | Corner ledge 7 up, above the knob | hook | 7 | 9.4 | +2.4 | roomy |
| style_lab | 2 - Rapunzel Crossing | 17-wide dye pool | rope_glide | 17 | 33.2 | +16.2 | roomy |
| style_lab | 3 - Tony's Makeover | Corner ledge 7 up, above the knob | launch | 7 | 9.1 | +2.1 | roomy |
| style_lab | 3 - Tony's Makeover | Corner ledge 7 up, above the knob | spring | 7 | 11.7 | +4.7 | roomy |
| style_lab | 3 - Tony's Makeover | Corner ledge 7 up, above the knob | hook | 7 | 9.4 | +2.4 | roomy |

Measured reach: `carry_reach_12` 23.89, `carry_reach_13` 25.2, `carry_reach_2` 11.2, `carry_reach_9` 20.1, `glide_reach_0` 12.22, `glide_reach_9` 33.22, `launch_rise` 9.12, `spring_rise_min` 11.66

## 2. Sloppy players: does it survive a person's timing?

Each level's playthrough bot, rerun with 130-330 ms reactions, aim off by up to
6 px and button holds 25 % too long or short. Clean = every check passed.

| Level | Clean runs | Most common first failure |
|---|---|---|
| level_01 | 24/24 | - |
| level_02 | 8/24 | R2: hair catch from the far trench rings the second bell (7x); R2: both in the exit clears L2 (4x); R1: both climb the shelves to the door (4x) |
| level_03 | 24/24 | - |
| level_04 | 23/24 | R2: the cannonball punches the pompadour through the perm-set gel (1x) |
| level_05 | 23/24 | R3: Long Straight lassos the gate lever (1x) |
| level_06 | 17/24 | R1: pompadour's dash takes out the clipper bot (4x); R3: wave 3 drops its robots through the vents (3x) |

## 3. Play log: where people (and sloppy bots) die, and how long rooms take

| Source | Level | Room | Sessions | Starts | Clears | Deaths | Median time (s) | Top causes |
|---|---|---|---|---|---|---|---|---|
| bot-sloppy | level_01 | 1 - Mirror, Mirror | 24 | 24 | 24 | 0 | 10.6 | - |
| bot-sloppy | level_01 | 2 - The Washing Basin | 24 | 24 | 24 | 0 | 9.9 | - |
| bot-sloppy | level_01 | 3 - The Gel Curtain | 24 | 24 | 24 | 0 | 11.0 | - |
| bot-sloppy | level_02 | 1 - Return to Sender | 24 | 24 | 20 | 4 | 29.0 | Scissor 4 |
| bot-sloppy | level_02 | 2 - Scissor Corridor | 20 | 20 | 8 | 8 | 42.4 | Scissor 8 |
| bot-sloppy | level_03 | 1 - Blow-Dry Bar | 24 | 24 | 24 | 0 | 12.7 | - |
| bot-sloppy | level_03 | 2 - Shampoo Station | 24 | 24 | 24 | 0 | 20.1 | - |
| bot-sloppy | level_03 | 3 - Rinse & Repeat | 24 | 24 | 24 | 0 | 10.6 | - |
| bot-sloppy | level_04 | 1 - The Perm Rollers | 24 | 24 | 24 | 0 | 14.9 | - |
| bot-sloppy | level_04 | 2 - Setting Lotion | 24 | 24 | 23 | 0 | 13.9 | - |
| bot-sloppy | level_04 | 3 - Double Return | 23 | 23 | 23 | 0 | 13.8 | - |
| bot-sloppy | level_05 | 1 - Extension Bar | 24 | 24 | 24 | 0 | 9.8 | - |
| bot-sloppy | level_05 | 2 - The Up-Do | 24 | 24 | 24 | 0 | 8.7 | - |
| bot-sloppy | level_05 | 3 - Tangles | 24 | 24 | 23 | 1 | 9.9 | ClipperBot 1 |
| bot-sloppy | level_06 | 1 - Closing Time | 24 | 24 | 20 | 4 | 29.8 | ClipperBot 4 |
| bot-sloppy | level_06 | 2 - The Chair | 20 | 20 | 20 | 0 | 23.2 | - |
| bot-sloppy | level_06 | 3 - Rush Hour | 20 | 20 | 17 | 3 | 23.3 | Scissor 3 |
| bot-sloppy | level_06 | 4 - The Barber Bot | 17 | 17 | 17 | 0 | 12.1 | - |
| human | level_01 | 1 - Mirror, Mirror | 4 | 8 | 0 | 0 | - | - |
| human | level_01 | 3 - The Gel Curtain | 4 | 0 | 4 | 0 | - | - |
| human | level_02 | 1 - Return to Sender | 4 | 16 | 0 | 0 | - | - |
| human | level_03 | 1 - Blow-Dry Bar | 4 | 16 | 0 | 0 | - | - |
| human | level_04 | 1 - The Perm Rollers | 4 | 4 | 0 | 0 | - | - |
| human | level_05 | 1 - Extension Bar | 4 | 4 | 0 | 0 | - | - |
| human | level_06 | 1 - Closing Time | 4 | 8 | 0 | 0 | - | - |
| human | level_06 | 4 - The Barber Bot | 4 | 0 | 4 | 0 | - | - |

### Death heatmaps

Red dots: people. Orange dots: sloppy bots.

**level_02_R1**

![level_02_R1](heatmaps/level_02_R1.png)

**level_02_R2**

![level_02_R2](heatmaps/level_02_R2.png)

**level_05_R3**

![level_05_R3](heatmaps/level_05_R3.png)

**level_06_R1**

![level_06_R1](heatmaps/level_06_R1.png)

**level_06_R3**

![level_06_R3](heatmaps/level_06_R3.png)

## How to read it

- **Margins** catch layout that is too tight (or impossible) for a move, with no play at all.
- **Sloppy runs** catch steps that need near-perfect timing: a step that fails for a
  bot with human reaction times will fail for a lot of people. A failure can also be the
  bot's own script being brittle; the first-failure label says which step to look at.
- **The play log** is the only part that says anything about people. It records by
  itself on every playthrough (local files only), so short sessions from friends add up.
- None of this measures *fun*. Use it to find the rooms worth watching someone play.
