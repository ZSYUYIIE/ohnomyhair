# Four haircuts, six chapters: who plays what, where

> Follows `four_haircut_expansion.md` (the Afro and Long Straight abilities). This doc fixes how
> the four haircuts fit the campaign without breaking the levels that were built for two.
> Rules in code: `scenes/systems/style_rules.gd`. Per-room data: `Room.styles`, `Room.gates`.
> Generated overview of every room: [`docs/levels/gate_graph.md`](../levels/gate_graph.md).

## The problem

Levels 1-3 and the finale were designed, tuned and bot-tested for **Twin-Tails + Pompadour**
only. The expansion then let any pair into any room:

- a styling chair in **every** room offered all four haircuts (including two of the same);
- Tony's scissors cycled a hit player through all four, ignoring the friend's haircut;
- hints named player slots ("P1: HOLD G to glide"), which lie as soon as haircuts move.

So most rooms could be skipped (a lasso pulls levers from afar) or soft-locked (no Pompadour =
no gel smash, no parry), and nothing checked which.

## The rule: a room declares who can play it

Every room carries three pieces of data (set by the level builders):

| Field | Meaning |
|---|---|
| `starting_hair` | The pair (P1, P2) the room starts and restarts with. |
| `styles` | The haircuts its chair offers. Two = the room's own pair, so the chair only swaps roles (plus heal + checkpoint). Fewer than two = no chair. |
| `gates` | The room's obstacles, each passable by **any one** of a few verbs (`dash_gel`, `carry`, `spring`, `hook`...). |

`StyleRules.verbs(pair)` lists what a pair can do: each haircut's own verbs plus the combos
that need both (sling, catch & toss, cannonball, catch & return, rope glide).

**The contract** (`tests/test_gates.gd`, 191 checks): for every room, every distinct pair from
`styles` has a verb for every gate. Gates must only list verbs that really work in that room's
geometry; the bot playthroughs (`tests/test_level_0N.gd`) prove one pair actually does it.

Also:
- **Two friends never share a haircut.** The chair won't confirm a duplicate.
- **Tony's restyle stays inside the room's set** and skips the friend's haircut
  (`StyleRules.next_style`); when the set is just the pair, the two friends swap instead.
- **Hints are written per haircut**: `"{tt}: HOLD {tt.skill} to glide"` resolves at runtime to
  whoever wears twin-tails and their key (`scenes/ui/hair_hint.gd`).

## The campaign: one pair per chapter, free choice only at the end

| # | Chapter | Pair (P1 / P2) | New thing | Chair |
|---|---|---|---|---|
| 1 | Fresh Cut | Twin-Tails / Pompadour | glide, dash, carry, launch, sling | swap roles |
| 2 | Return to Sender | Twin-Tails / Pompadour | parry, Hair Catch | swap roles |
| 3 | Wash & Blow-Dry | Twin-Tails / Pompadour | dryers, showers, carry up the warm air (Hair-copter is faster) | swap roles |
| 4 | **Perm Day** (new) | Afro / Pompadour | spring, cannonball, double return | swap roles |
| 5 | **Extensions** (new) | Twin-Tails / Long Straight | hook, rope, lasso | swap roles |
| 6 | The Barber (was 4) | TT / Pomp, swapped in room 2 | Rush Hour waves, then the boss | **all four** in the boss arena (room 4) |

Each new haircut is introduced next to one the players already know, in a chapter whose rooms
need it. The finale's arena is the only room that offers all four, and all six pairs pass its
gates: Tony can be dazed by anyone (bait a charge into a wall; parry, return or cannonball are
faster), and the corner ledges above his head knob can be reached by a launch, a spring or a
hook (the arena has gold rings). Rush Hour (room 3) keeps the swapped Twin-Tails / Pompadour pair.

### Chapter 4: Perm Day (Afro + Pompadour), `docs/levels/level_04.md`

This pair has no lever puller, so every switch is a bell and every height is a spring.

1. **The Perm Rollers.** The shelf is 11 up: a Pompadour launch lifts the Afro 9 (short, and
   the room says so); a wound-up Afro springs the Pompadour 12-13. Up there, a parried scissor
   rings the bell that opens the floor-level staff door; the Pompadour drops back down.
2. **Setting Lotion.** Orange perm-set gel fills the room and sets again 2.5 s after breaking.
   A plain dash bounces; the cannonball (13.8 tiles flat) punches through and the Afro runs
   through before it closes. Every spot the cannonball works from is under a shower: wet perms
   won't spring, so go between sprays or dry off.
3. **Double Return.** A dispenser fires right. A plain parry sends a scissor back into the left
   bell; the right bell is past the friends, so only a scissor the Afro catches in the trench,
   turns around and returns can ring it.

### Chapter 5: Extensions (Twin-Tails + Long Straight), `docs/levels/level_05.md`

1. **Extension Bar.** The bar is 9 up: Long Straight hooks the ring over its counter and lowers
   a hair rope; twin-tails climbs. The gate lever is 4 above the bar top, out of jump reach,
   so Long Straight lassos it.
2. **The Up-Do.** A 13-up tower: Long Straight rides twin-tails up the dryer (the L3
   Hair-copter with a new rider), then twin-tails carries her over 21 tiles of dye (a carry
   reaches about 25 tiles from 13 up, 20 from 9 up). She can lasso the clipper bot while hanging.
3. **Tangles (exam).** Ring, rope, a carry over 18 tiles from 9 up with a shower over the take-off
   end, a clipper bot, and a gate lever 5 up that only the lasso reaches.

## Measured numbers (tiles)

| Move | Reach |
|---|---|
| Jump | 3.5 up, 6.2 across |
| Pompadour launch | rider's feet 9.1 above the floor |
| Afro spring | 11.7 (minimum charge) to 13.1 (full) |
| Cannonball | 13.8 flat, low (1.4 high) |
| Long Straight rope | 10 down; climb takes 1.8 s |
| Hook / lasso | 9.4 / 6.25 radius, line of sight |
| Carry (Twin-Tails + any) | 8.9 flat, 16.5 from 6 up, 20 from 9 up, 25 from 13 up |
| Glide alone | 12.5 flat, 33 from 9 up |

## Also fixed while auditing

- **Finale room 1:** the friends spawned next to the hot flat iron (P2 at column 4, iron at
  5-6). Spawns moved two tiles clear.
- **Tonics before the boss:** the teammate's Rush Hour room (finale room 3) hands out growth
  tonics between waves, so the finale no longer needs the extra one on room 2's exit ledge.
  Chapter 3 no longer has a tonic (it has no damage source).
- **Hints that gave the answer away** ("P1 stands on P2's head, P2 presses K") now name the move
  being taught instead.
- **The title screen** lays out six chapters, three per row.

## Next

- Art for chapters 4 and 5: they reuse the existing tile sets and walls for now.
- A full survival playthrough of the boss with Afro and Long Straight. The physical route
  check now covers a real wall crash and corner stomp with all six pairs; it uses fixed
  starting positions and temporary immunity, so it does not measure survival difficulty.
- Optional later chapter: free choice in more rooms, now that the gate check makes it safe.

## Integration review

- Save version 2 uses stable chapter IDs. Unversioned `level_4` records belonged to the old
  Barber finale and migrate there, leaving Perm Day and Extensions to be played in order.
  Unversioned expansion saves cannot distinguish an old Barber record from a new Perm Day
  record; ambiguous chapter-4 records are treated as the legacy finale to avoid skipping a
  new chapter. Existing chapter-5/6 records are retained, with unlock prerequisites enforced.
- Styling checkpoints keep the chosen pair but restart at authored room spawn points.
  A fixed chair offset embedded a player in Extensions' tower or on the finale's flat iron.
  Chair placement now uses the spawn midpoint, clear of those obstacles.
- `tests/test_checkpoints.gd` checks selection and idle restarts at all 17 campaign chairs.
  `tests/test_menu.gd` checks migration, records and sequential unlocks.
- `tests/test_boss_pairs.gd` physically reaches the high corner with launch, spring or hook,
  baits a wall crash and lands a stomp for each of the six allowed pairs. The existing finale
  playthrough covers all three rounds with Pompadour + Twin-Tails.
