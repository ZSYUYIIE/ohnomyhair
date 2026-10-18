# Interactive UI and asset refresh

The supplied Asset Library v1 establishes the warm cartoon salon style: peach, cream,
lilac, coral upholstery, chrome, blue glass and clean purple outlines with cel shading.
The existing playable characters, room backdrops and level layouts are preserved.

## Menus and chapter art

The title uses the latest default branch's painted `title_cover.png`, with matching
Start Game / About cutouts on native buttons. The cover's own art, hover/focus motion,
pressed motion, hand cursor and menu SFX provide feedback; no extra pink frame is
drawn around the painted buttons. Its desktop Quit confirmation and new app icon are
retained. Start Game plays the opening, then opens the map; launch itself stays on
the title. I or the map's Opening button replays the CG and returns to the title.

Start Game opens the supplied illustrated Salon Map. Separate native buttons,
badges, locks and completion marks sit over the cleaned background.
Both the illustrated destination and its label select a chapter; Play or P launches
it. The existing sequential unlocks, saved records and finale's `???` name remain.
Locked illustrations explain their prerequisite. See [salon_map.md](salon_map.md)
for the pack README, asset provenance and scaling details. The earlier chapter-card
illustrations remain available as source assets.

The map canvas and hit areas scale uniformly together. Chapter details and shortcuts
occupy separate rows with a 14px design-space gap. The HUD reserves an 88px footer with three cards in one HBox;
both text rows fit in 68px cards with a 10px bottom inset. Camera framing uses the
same footer height so the complete room stays visible above the HUD.

## Gameplay assets

- Four editable `tiles_poster.svg` atlases redraw the floor/platform material with
  cream caps, shaded checker surfaces and chapter palettes. Each retains the old
  128×160 / 4×5 atlas layout, 32px cells, tile IDs and collision polygons.
  `tools/art/make_poster_tiles.py` writes SVG source, without editing bitmap images.
- The assistant uses the hand-authored vector puppet in `assistant_doodle.gd`:
  flat coral fills, purple ink, a yellow eye and jointed scissor arms. Walking steps,
  firing snips, wind-up, upright running, dazed sway, hurt recoil and collapse each
  have their own pose. Running retains the standing torso, head and knob dimensions;
  longer strides and arm swings convey speed. Collision and combat timings remain.
  The previous glossy `assistant_poster.png` is superseded.
- `chair_flat.svg` is the current in-game chair: an editable 112×120 vector with
  flat coral fills, one shadow tone and consistent 2.5px purple outlines, matching
  the original game props. Only the surprise swap chair remains, drawn at 64×75
  world units with its existing trigger area; the used chair darkens. Automatic
  spawn-point chairs and their menu are archived in `archive/spawn_styling`.
  Room checkpoints restore authored spawn positions and starting haircuts.
- Gel, moving platforms and exit doors have glossy native drawing. The two original
  player animation sets and all room background PNGs are unchanged.

## Opening and navigation

The eleven clean supplied opening panels and English subtitles total 39 seconds.
Start Game begins the introduction, including for returning players; finishing or
skipping opens the map at the latest unlocked stage. Launching the app alone does
not play it. The map's Opening button / I replays it and returns to the title.
Saved chapter records are preserved in both routes.

Navigation shortcuts are named actions in `navigation_shortcuts.gd`. The title,
chapter menu and HUD show relevant keys; the Shortcuts guide lists the full set:

| Context | Keys |
|---|---|
| Menus | Arrows / Tab, Shift+Tab; Enter / Space activates; mouse point and click |
| Title | I watches the opening; F1 / H opens help |
| Chapters | Left / right or 1–4 / numpad selects unlocked chapters; P plays; Esc backs out |
| Gameplay | Esc pauses/resumes; R restarts the room; F1 / H pauses and opens help |
| Pause / death | R restarts; Esc resumes a pause but cannot dismiss death |
| Help | Tab to the tabs, left/right switches; wheel / Page Up / Page Down scrolls; Esc / F1 / H closes |
| Surprise chair | Walking through its zone swaps the two haircuts once |
| Opening | Click / any key / any pad button turns a page (0.25 s cooldown); Esc / pad B / Start / Skip ends it |
| P1 | A/D move; W jump; G skill/glide/carry/lever; F whip; S drop/release/interact |
| P2 | Left/right move; Up jump; K dash/launch; L parry; Down drop/release/interact |

The in-game Hair combos page documents carry-and-glide, launch, sling dash, hair catch
and warm-air interactions. Abilities follow the haircut; movement keys follow the player.

## Audio and provenance

Claude's existing audio work was copied from the sibling `ohnomyhair-audio` worktree,
including its 38 gameplay event hooks and original `tools/audio` synthesizers. That
worktree was not edited. Audio uses a bounded 12-voice pool, UI/SFX/Music buses, pitch
variation, a retrigger guard and music changes for the active level/boss. Headless
runs are silent. The audio is synthesized locally; no external music was downloaded.

Generated assets use the built-in image tool. Exact prompts for the four chapter
illustrations and chair are in `chapter_chair_generation_prompts.json`; the title edit
and robot prompts are in `interactive_generation_prompts.json`. The updated manifest
records their hashes and dimensions. Supplied source metadata and timing remain in
`teammate_library_v1`; that folder describes the original delivery. Earlier generated
title drafts remain in `art_src/ui`, excluded from imports. Textures use lossless
compression, linear filtering and no mipmaps. Fonts are unmodified Google Fonts
[Fredoka](https://github.com/google/fonts/tree/main/ofl/fredoka) and
[Nunito](https://github.com/google/fonts/tree/main/ofl/nunito), with their SIL OFL licenses.
`SalonArrows.ttf` and `SalonIcons.ttf` are small, renamed SIL OFL subsets of Noto Sans
Symbols / Symbols 2 for Web, where system fallback fonts are unavailable. Original
sources stay in `art_src/fonts`; `tools/art/build_ui_symbols.py` rebuilds the seven
glyphs and matches Fredoka's line metrics so symbol fonts do not enlarge menu rows.

## Validation

Fourteen suites pass 565 checks, including the finale playthrough and 21 attack / dodge
checks. The opening uses the normal renderer for mouse delivery; the rest run headless.
Tests use isolated saves. Logs are `.godot/release-final-*.log`. GPU renders cover all
opening panels, title/chapter cards at 1280×720 and 960×540, a letterboxed 1280×960
window, help/shortcuts, HUD and overlays; captures are `.godot/poster-shots`.

The flat chair revision was imported and GPU-rendered; all 36 checkpoint checks pass.

Salon Map / upright run follow-up: six targeted suites pass 235 checks. The 52 GPU
layout checks include actual illustration / label clicks, locked-stop explanations
and uniform map fitting at five window sizes. Menu / navigation and finale / boss
attack regressions also pass; logs are `.godot/map-*.log`. Combat mechanics were
not changed by this follow-up.
