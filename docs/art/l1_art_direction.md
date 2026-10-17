# Art direction: doodle cartoon (Level 1)

> Applies to Level 1 so far. L2 and L3 still use the greybox tiles and SalonDecor walls, but they
> already share the new characters and the restyled lever, lift, gel, dye basin and exit.
> Asset list and provenance: [asset_manifest.json](asset_manifest.json).

## Game frame

- 2D side view, single-screen rooms of 1280×720, 32 px tiles, Godot 4.7 (Compatibility).
- Characters are about 60 px tall on screen, and their hitbox is 28×44.
- All art is made at its final in-game size (1×), drawn supersampled and downscaled.

## Visual system

| Axis | Rule |
|---|---|
| **Shapes** | Round means safe or friendly (characters, cabinet corners, gel). Sharp means danger. Yellow knobs and handles mean interactive. |
| **Silhouette** | The hair is the character. Bodies are plain sticks with ball hands and feet, a cream round head and two oval eyes, and no mouth. |
| **Value** | Three bands:<br>• walls are light and low-saturation;<br>• cabinets are mid-tone caramel;<br>• characters and props have dark ink outlines and saturated fills. |
| **Colour** | Ink `#2b2140`.<br>Characters: P1's hair `#ff5fa2` and P2's hair `#3a8fd6` are **reserved for the players**. A wall may only use them washed out (≤ 30% tint).<br>Gameplay roles: danger `#e74c3c`, dye `#8e44ad`, gel `#9be7d8`, interactive `#f1c40f`, exit `#2ecc71`.<br>Cabinets: body `#d6b08a` and countertop `#faf4e8`. |
| **Lines** | Characters, tiles and props: dark ink about 3 px, with a slight hand wobble.<br>Backgrounds: 1.5–2 px lines in a darker tint of the wall colour, never ink. |
| **Shading** | None: flat colour only, with no gradients or cast shadows, because the characters have none. |
| **Surfaces you can stand on** | Every solid top has an ink line and a cream countertop. Backgrounds never contain a long horizontal edge that could be mistaken for a ledge. |
| **Motion** | Exaggeration comes from code: squash on landing, stretch on jumps, and a squash when launching a friend. Skill poses come from the sprite sheets. |

## Characters

- **Source:** two AI-generated sheets (`art_src/characters/*_sheet.png`). Each has 6 columns × 8 rows of 181 px cells, with body and hair drawn together.
- **Haircut swap:** because the two bodies are identical, swapping haircuts means swapping `SpriteFrames` (`HairAbility.frames`). There are no separate hair layers.
- **Normalising** (`tools/art/normalize_characters.py`):
  - removes the generator's alpha haze and the red edge fringe;
  - removes pieces that bled in from neighbouring cells;
  - scales by 0.45, so feet to forehead is about 45 px, matching the hitbox;
  - pins ground poses to the foot line and air poses to the standing face height;
  - writes one 136×128 strip per animation, with the feet at (68, 104).
- **Animations:** `idle run jump fall hang` for both, plus:
  - twin-tails: `attack glide carry_glide pull`;
  - pompadour: `parry dash`.

  `Player._process` picks one from movement, unless the haircut's `anim()` asks for a skill pose.
- **Known gaps:**
  - Some source frames were cut at their cell edge. You'll see a hard edge on the tail at the end of `pull`, and on the hair tip in `dash` 2–3.
  - There are no hurt, death or chair-sitting poses. Hurt uses the existing blink.

## World (`tools/art/make_l1_art.py`)

- **Tiles:** `tiles_salon.png`, a 4×5 atlas.
  - Each solid tile is chosen by which neighbours are solid (1 up, 2 right, 4 down, 8 left). Edges that meet air get ink, a rounded outer corner, and a countertop when the top is open.
  - There are 3 extra enclosed variants and a one-way shelf at (3, 4).
  - `LevelBuilder` paints it when `tile_atlas` is set.
- **Backgrounds:** one painted wall per room, with no collision cues:
  - Mirror, Mirror: striped wall, mirrors, barber poles, and the shop's two haircut sketches;
  - The Washing Basin: aqua wall tiles, pipes, shower hoses, bubbles;
  - The Gel Curtain: lilac wall, pale round ooze from the ceiling, gel tubs, pump bottles.
- **Props:**
  - Fixed images: lever (48×48, off | on) and exit door (64×96).
  - Nine-slices for props that come in any size: gel, lift and dye (64×64, edge margins set in code by `PropArt`).
- **Drawn by code, so no text is ever baked into images:** the OPEN sign, the exit pips, the gel regrow drips, and the dye basin rims.

## Level 3 stations (`tools/art/make_salon_props.py`)

Drawn with the same helpers as `make_l1_art.py` (wobbly ink, flat fill, supersampled):

- **Hair dryer** `prop_dryer.png` (64×64, base at the bottom center): coral body, because P1's pink is reserved for the players.
- **Shower head** `prop_shower.png` (64×40, mount at the top center).
- **Growth tonic** `prop_tonic.png` (24×36, centered).
- **Hot flat iron** `prop_iron.png` (two 64×24 frames: cold | red-hot).

Motion stays in code: warm air, water lanes and warning drips, the tonic's bob, iron steam.
On the characters: a soaked friend's sprite is tinted `WET_TINT` (cool blue) with drips; twin-tails
shows the `pull` pose while holding a caught scissor; every hit throws a `HairSnip` puff in the
haircut's colour.

## Rebuild everything

```
python -I tools/art/normalize_characters.py
python -I tools/art/make_l1_art.py
python -I tools/art/make_salon_props.py
godot --headless --path . --import
godot --headless --path . --script res://tools/build_character_frames.gd
godot --headless --path . --script res://tools/build_level_01.gd
```

Then check the art in context with `godot --path . --script res://tools/render_rooms.gd`.

## Next (not done)

- L2/L3 rooms: their own backgrounds, plus enemy, Boss, chair and turret art.
- HUD portraits could crop the idle frame's head instead of using colour blocks.
- The dye pools in L1 rooms 2 and 3 sit mostly behind the bottom HUD bar: only the top 16 px of the dye shows. This is a layout issue, and it was already like this in the greybox.
