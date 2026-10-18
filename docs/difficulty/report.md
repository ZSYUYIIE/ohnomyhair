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
| level_06 | 1 - Closing Time | 9-wide dye pool, both friends | carry | 9 | 11.2 | +2.2 | roomy |
| level_06 | 2 - The Chair | 6-up cliff | launch | 6 | 9.1 | +3.1 | roomy |
| level_06 | 4 - The Runaway Assistant | Corner ledge 7 up, above the knob | launch | 7 | 9.1 | +2.1 | roomy |

Measured reach: `carry_reach_12` 23.89, `carry_reach_2` 11.2, `carry_reach_9` 20.1, `glide_reach_0` 12.22, `launch_rise` 9.12

## 2. Sloppy players: does it survive a person's timing?

Each level's playthrough bot, rerun with 130-330 ms reactions, aim off by up to
6 px and button holds 25 % too long or short. Clean = every check passed.

| Level | Clean runs | Most common first failure |
|---|---|---|
| level_01 | 24/24 | - |
| level_02 | 23/24 | R1: both climb the shelves to the door (1x) |
| level_03 | 24/24 | - |
| level_06 | 24/24 | - |

## 3. Play log: where people (and sloppy bots) die, and how long rooms take

| Source | Level | Room | Sessions | Starts | Clears | Deaths | Median time (s) | Top causes |
|---|---|---|---|---|---|---|---|---|
| bot-sloppy | level_01 | 1 - Mirror, Mirror | 24 | 24 | 24 | 0 | 10.6 | - |
| bot-sloppy | level_01 | 2 - The Washing Basin | 24 | 24 | 24 | 0 | 9.9 | - |
| bot-sloppy | level_01 | 3 - The Gel Curtain | 24 | 24 | 24 | 0 | 11.0 | - |
| bot-sloppy | level_02 | 1 - Return to Sender | 24 | 24 | 23 | 1 | 29.7 | Scissor 1 |
| bot-sloppy | level_02 | 2 - Scissor Corridor | 23 | 23 | 23 | 0 | 44.7 | - |
| bot-sloppy | level_03 | 1 - Blow-Dry Bar | 24 | 24 | 24 | 0 | 12.7 | - |
| bot-sloppy | level_03 | 2 - Shampoo Station | 24 | 24 | 24 | 0 | 20.1 | - |
| bot-sloppy | level_03 | 3 - Rinse & Repeat | 24 | 24 | 24 | 0 | 10.6 | - |
| bot-sloppy | level_06 | 1 - Closing Time | 24 | 24 | 24 | 0 | 30.1 | - |
| bot-sloppy | level_06 | 2 - The Chair | 24 | 24 | 24 | 0 | 23.2 | - |
| bot-sloppy | level_06 | 3 - Rush Hour | 24 | 24 | 24 | 0 | 23.2 | - |
| bot-sloppy | level_06 | 4 - The Runaway Assistant | 24 | 24 | 24 | 0 | 12.1 | - |
| human | level_01 | 1 - Mirror, Mirror | 6 | 12 | 0 | 0 | - | - |
| human | level_01 | 3 - The Gel Curtain | 6 | 0 | 6 | 0 | - | - |
| human | level_02 | 1 - Return to Sender | 6 | 24 | 0 | 0 | - | - |
| human | level_03 | 1 - Blow-Dry Bar | 6 | 24 | 0 | 0 | - | - |
| human | level_04 | 1 - The Perm Rollers | 5 | 5 | 0 | 0 | - | - |
| human | level_05 | 1 - Extension Bar | 5 | 5 | 0 | 0 | - | - |
| human | level_06 | 1 - Closing Time | 6 | 12 | 0 | 0 | - | - |
| human | level_06 | 4 - The Runaway Assistant | 6 | 0 | 6 | 0 | - | - |

### Death heatmaps

Red dots: people. Orange dots: sloppy bots.

**level_02_R1**

![level_02_R1](heatmaps/level_02_R1.png)

## How to read it

- **Margins** catch layout that is too tight (or impossible) for a move, with no play at all.
- **Sloppy runs** catch steps that need near-perfect timing: a step that fails for a
  bot with human reaction times will fail for a lot of people. A failure can also be the
  bot's own script being brittle; the first-failure label says which step to look at.
- **The play log** is the only part that says anything about people. It records by
  itself on every playthrough (local files only), so short sessions from friends add up.
- None of this measures *fun*. Use it to find the rooms worth watching someone play.
