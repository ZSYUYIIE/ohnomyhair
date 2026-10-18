# Two friends, one escape

Current direction, based on the user's **Art Review 04 — A Clearer Escape Story** board.
The board is the visual and narrative reference; its review/approval notes are not game UI.

## Cause and effect

1. Two friends arrive at the salon at closing time, hoping for a fresh look.
2. The barber steps away and leaves his robot assistant in charge.
3. The assistant malfunctions: one snip too many reveals the friends' hair powers.
4. The robot locks the front door. Pompadour steps between its scissors and Twin-Tails.
5. Twin-Tails notices the service route. They choose to trust each other and run together.
6. They cross the salon's service rooms, using those two powers to protect each other.
7. The assistant and its backup block the back door. They overcome it and escape together.

## Playable route

| Chapter | Place in the escape | Gameplay |
|---|---|---|
| 1 — Fresh Cut | Discover the service route after the front door locks | Glide, dash, carry, launch and sling |
| 2 — Return to Sender | The assistant's scissor machines block the passage | Parry, catch and ring the service bells |
| 3 — Wash & Blow-Dry | Cross the wash rooms on the way to the back workshop | Warm air, wet hair and co-op flight |
| 4 — The Assistant | Reach the back door through the robot's defenses | Chair role reversal, Rush Hour, three-phase assistant fight |

This change supplies story context in the menu/help and a matching ending. It does not
implement the board's 11-shot animated opening or replace the title with its assembled art;
those need the individual production layers rather than a flattened review board.

## Characters and art

The playable cast is always the same two friends: pink Twin-Tails and blue Pompadour.
Use their original sprites and full-size-sheet portraits. Preserve their proportions,
dark stick limbs and outlines, simple oval faces, and mouthless expressions. Emotion
comes from eyes, posture and gesture, as shown on the board.

Chairs and damaging boss scissors may swap the two familiar haircuts. They do not
introduce another person or a third haircut. The front-end and chair UI expose only these
two styles. Boss hook rings and the optional Style Lab entry are removed.

Perm Day, Extensions and Style Lab, plus Afro and Long Straight art/ability sources,
are archived under `archive/four_haircut_prototype` with `.gdignore`, outside the playable
resource set. Afro's spring/launch overlap is resolved by retiring the prototype.

## Progress and verification

The finale retains `level_06.tscn` and save ID `the_barber` internally to preserve records;
the player sees chapter 4, The Assistant. The first three chapters unlock it sequentially.
Old expansion records remain in existing saves but neither unlock nor clear another chapter.

Campaign tests are levels 01, 02, 03 and 06. Gate tests check every room allows only the
two story haircuts. Menu tests cover legacy and expansion saves, and checkpoint tests
cover all campaign stations. The boss-route check uses fixed setup/immunity; the finale
playthrough also tests the three combat phases. Archived prototype tests are historical.
