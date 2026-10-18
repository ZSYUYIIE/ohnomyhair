# Four haircuts: the co-op expansion

> **Historical prototype — retired 2026-10-18.** See [the current escape story](story_escape.md).
> The extra art, abilities, stages and tests are preserved under `archive/four_haircut_prototype`.

The campaign remains four chapters with sequential unlocks. **Style Lab** is a separate,
always-available three-room practice adventure on the title screen. Clearing it does not
record campaign clears or unlock later chapters.

## The roster

| Haircut | Skill (P1 G / P2 K) | Attack (P1 F / P2 L) |
|---|---|---|
| Twin-Tails | Hold to glide/carry; pull levers; catch parried scissors | Whip and stun |
| Pompadour | Dash through gel; launch a rider | Parry scissors |
| Afro | Hold on the floor to charge; release with a rider to spring them upward | Short shield; hold to catch a parried scissor, release to return it |
| Long Straight | Hold on a ledge to lower a rope; airborne skill hooks a visible gold ring | Pull/stun a light bot or remotely pull a lever |

The hairstyle, not the player slot, owns the ability. Movement keys do not change.
Both new haircuts have their own sprite poses and HUD portraits. The original hair-swap
chair now exchanges the actual equipped pair, including the new styles.

## Cooperation

**Cannonball:** Afro charges skill for at least 0.2 seconds. Pompadour stands on Afro's
head and holds their own skill. Afro releases. Pompadour flies horizontally as a powered
drill, breaks reinforced orange-striped gel, and can daze Tony. An ordinary dash or a solo
sling cannot break reinforced gel. Without Pompadour's input, the spring launches a rider
upward instead.

**Rope ride / glide release:** Long Straight stands near a ledge facing outward and holds
skill. A friend holds jump near the hanging hair to attach and climb; Down descends.
Left/right releases with a jump and horizontal boost. Twin-Tails can then glide much farther
from the elevated launch point. Releasing the provider's skill, changing hair, or dying
releases the rope. Climbing and grappling respect collisions. This is an assisted rope ride,
not a free pendulum simulation.

**Double return:** Pompadour parries a scissor first. Afro holds attack to catch the blue
scissor, then releases it as a golden horizontal return. Red scissors cannot be caught;
the timed shield can absorb their damage.

## Styling chairs and checkpoints

Bring both living friends within reach of a gold-marked styling chair and press **S / Down**.
The game pauses while each player chooses one of the four haircuts. Previewing a selection
does not apply it. Confirming applies both styles, heals and dries both friends, and records
a room checkpoint. Esc cancels without changing styles or the checkpoint.

Death/restart rebuilds enemies, walls and switches, while retaining the chosen styles and
safe chair spawn positions. Level time and deaths still carry over. Entering a new room
clears the old room checkpoint; replay starts fresh. Checkpoints last for the current run;
they are not a persistent mid-level save slot.

## Water and Tony

Wet Afro hair cannot charge, shield or catch. Dryers restore these abilities through the
existing drying system. Existing wet Twin-Tails/Pompadour rules continue to apply.

Tony's scissors rotate a surviving player through the four haircuts only when the hit
actually removes HP. Shields, parries and invincibility prevent the restyle; the new haircut
does not heal the player. The HUD and a short banner identify the new skill. Gold hook rings
in boss arenas give Long Straight a route to high ground. The boss still takes HP damage
only from a falling stomp while dazed.

## Style Lab rooms

1. **The Bounce Studio:** learn charged Afro/Pompadour cannonballs, wet hair and drying.
   A full-height reinforced curtain prevents a solo dash shortcut.
2. **Rapunzel Crossing:** Long Straight hooks a high one-way shelf and lowers a rope.
   Twin-Tails climbs, releases and glides to a lever that lowers a bridge for the provider.
3. **Tony's Makeover:** practice restyling, defense and boss weak-point rules, with a styling
   chair and hook rings for recovery and changing strategy.

Mohawk cutting, bald laser reflection, braided bridges, stored items, static-electric
circuits and gel-shaped hair platforms remain future design ideas. They are not represented
as implemented abilities in the UI.

## Validation

Final Godot 4.7.2 run: **264 passed, 0 failed** across eight suites (menu 49, combos 39,
L1 30, L2 29, L3 24, L4 42, new haircuts 34, Style Lab 17). `git diff --check` passes.
Rendered the title, new help content and scrolling, all three lab rooms, and the styling
menu at 1280×720, 960×540 and in a 4:3 window. Rebuild local screenshots with
`godot --path . --script res://tools/render_style_lab.gd` (output: `.godot/style-lab-shots`).

`tests/test_haircuts.gd` exercises new abilities with input and collisions, defenses, water,
LOS checks, forced restyles, selection/cancel, actual Down interaction, and checkpoint death
recovery. `tests/test_style_lab.gd` traverses the two authored co-op movement rooms using
both players' input, checks the boss's restyle projectile/victory wiring, and ensures practice
does not affect campaign progression. The original L4 suite covers the existing boss combat
loop; the lab victory-wiring check does not claim a complete human co-op boss playthrough.
