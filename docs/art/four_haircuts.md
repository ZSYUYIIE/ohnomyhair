# Afro and Long Straight character art

Created for the four-haircut expansion with the built-in OpenAI image-generation tool,
then normalized with `tools/art/normalize_new_haircuts.py`. No external asset pack is used.

Source: `art_src/characters/four_haircuts_sheet.png` (2172×724, RGBA, 6 columns × 2 rows).
Source SHA-256: `11d42e03da143cee9b60c52c56e81e545c8ddecbef4267b39b00f3eaaa215f95`.
Runtime: `assets/art/characters/{afro,long_straight}/poses.png` and `frames.tres`.
Each strip is 816×128: six 136×128 cells, feet at y=104; airborne poses align their face.
Faces are scaled to approximately 18 px high, matching the existing doodle characters.
The runtime sprites use lossless texture imports, alpha, no mipmaps, and linear character
filtering. State effects (shield, charge, rope, hook and lasso lines) are drawn by Godot.

Palette/shape locks: cream face, no mouth, dark-purple stick body and ball extremities,
thick dark ink, orange scalloped Afro silhouette, ankle-length violet straight hair. The
new art has a little generated fill variation; it is reviewed at native game scale rather
than treated as pixel art. Both strips and the source remain in the repository for rebuilds.

## Generation prompt

Create a production 2D game sprite sheet matching the reference doodle stick characters in
`assets/art/characters/twin_tails/idle.png`. Brand-new assets only. Exactly six equally spaced
columns and two equally spaced rows, transparent RGBA background, wide 3:1 canvas. Each slot
contains one full-body stick figure facing right, same scale, feet aligned, generous
transparent margins, no overlap across slots.

Row 1: orange Afro haircut character, huge round scalloped orange hair silhouette, cream
circular face, two simple dark oval eyes, no mouth, dark-purple stick torso/arms/legs with
ball hands and feet. Six poses: idle; running left foot forward; running right foot forward;
jumping arms raised; crouched braced shield with Afro puffed wide; crouched spring bounce
recoiling.

Row 2: Long Straight violet hair character, long smooth violet hair down to ankles, cream
circular face, two simple dark oval eyes, no mouth, same dark-purple stick body. Six poses:
idle; running left foot forward; running right foot forward; jumping; standing steady with
hair flowing down like a rope; lasso swinging forward.

Style locks: simple flat hand-drawn doodle, near-black purple `#2b2140` thick slightly wobbly
ink outlines, cream `#fff4df` face, saturated orange `#ee9a42` Afro and violet `#9467d5` Long
Straight Hair. No gradients, drop shadows, clothing, muscles, anime rendering or realistic
hair strands. Hair is the identity. No text, labels, scenery, weapons, grid lines, floating
standalone heads or cropped hair.

The generation output was copied into the project, alpha fringe was removed, and the cells
were cropped/aligned deterministically. `frames.tres` maps the six poses to movement and
ability animation names; it does not claim six frames for every individual animation.
