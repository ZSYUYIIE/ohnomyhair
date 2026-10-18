# Interactive UI and asset refresh

The supplied Asset Library v1 establishes the warm cartoon salon style: peach, cream,
lilac, coral upholstery, chrome, blue glass and clean purple outlines with cel shading.
The existing playable characters, room backdrops and level layouts are preserved.

## Menus and chapter art

The title background derives from the supplied gold title. Its baked Start Game and
About buttons were removed with built-in image generation, then replaced by real
Godot Buttons. Raised surfaces, shadows, hover/focus motion, depressed press states,
a hand cursor and Claude's menu SFX provide feedback. The title includes Watch opening.

Start Game opens four native chapter cards. Four dedicated 3:2 illustrations under
`assets/art/ui/chapters` replace the cropped opening frames. The image viewport is a
clipped 254×166 Control; titles and state labels occupy a separate opaque card area.
The final card shows a mysterious door with no boss artwork. Sequential progress
locks and the finale's `???` name remain. Focus and number shortcuts select unlocked
cards; the Play button or P launches the selected chapter.

## Gameplay assets

- Four editable `tiles_poster.svg` atlases redraw the floor/platform material with
  cream caps, shaded checker surfaces and chapter palettes. Each retains the old
  128×160 / 4×5 atlas layout, 32px cells, tile IDs and collision polygons.
  `tools/art/make_poster_tiles.py` writes SVG source, without editing bitmap images.
- The assistant sprite derives from the supplied robot illustration using built-in
  image generation with transparent output. Its red chest, yellow eye, scissor arms,
  chrome joints and red boots follow that reference. Charge squash, hurt flashes,
  dazed target glow and all boss collision/timing rules remain in code.
- `chair_flat.svg` is the current in-game chair: an editable 112×120 vector with
  flat coral fills, one shadow tone and consistent 2.5px purple outlines, matching
  the original game props. It replaces the overly glossy generated chair. Both
  styling checkpoints and the surprise swap chair use it; the used chair darkens.
  Trigger areas and gameplay behavior remain. The generated PNG is superseded.
- Gel, moving platforms and exit doors have glossy native drawing. The two original
  player animation sets and all room background PNGs are unchanged.

## Opening and navigation

The eleven clean supplied opening panels and English subtitles total 39 seconds.
First play on a fresh save shows them automatically; existing chapter records skip
the mandatory opening. Watch opening / I replays the complete introduction and
returns to the title. Neither replaying nor skipping a replay alters saved progress.

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
| Chair | S / Down opens near both friends; arrows / Tab select, Enter confirms, Esc cancels |
| Opening | Any key / mouse click / controller button skips |
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

## Validation

Twelve headless suites pass 500 checks: menu 81, opening 51, navigation 13, combos 50,
gates 108, checkpoints 36, boss pairs 4, story roster 8, and campaign levels 30/29/27/63.
Tests use isolated saves. Logs are `.godot/final-art-*.log`. GPU renders cover all
opening panels, title/chapter cards at 1280×720 and 960×540, a letterboxed 1280×960
window, help/shortcuts, HUD and overlays; captures are `.godot/poster-shots`.

The flat chair revision was imported and GPU-rendered; all 36 checkpoint checks pass.
