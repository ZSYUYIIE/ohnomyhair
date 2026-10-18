# Superseded generated UI drafts

Replaced by the teammate asset library on 2026-10-18. Retained for provenance only.

# Asset Library v1: title and Salon Map UI

The user's newest AI-generated overview is the visual reference. It is not an existing
production asset bundle. The current game assets were inspected and retained for gameplay;
this pass creates a title illustration and implements real Godot controls around it.

## Current visual target

- Gold bubble logo, airborne pink Twin-Tails and blue Pompadour, floating hair clippings.
- Warm peach salon, coral chairs, blue mirrors, lilac panels and checker floor.
- Dark purple outlines, cream panels, rounded Fredoka headings and Nunito body text.
- Start Game / About cover; a shared four-stop Salon Map with a lavender winding road.
- Stage locks enforce every earlier clear. The last stage stays `?` / `???` until cleared.
- HUD, pause, death, results, help, chair selection and boss bar share the same palette.

Start Game opens the map at the latest unlocked chapter. Clicking a stage selects it;
the footer Play button starts it. Back / Esc returns to the cover. Keyboard focus stays
inside each visible overlay. About opens the controls, combos and story guide.

## Sources and files

| File | Source / role |
|---|---|
| `art_src/ui/asset_library_reference_v1.jpg` | User-supplied AI overview, 1800Ã—2580; current reference |
| `assets/art/ui/poster/title_scene_gold.png` | Built-in image generation from that reference; 1672Ã—941 opaque PNG |
| `art_src/ui/storyboard_reference.png` | Earlier user-supplied art board; historical reference |
| `art_src/ui/title_scene_pink_draft.png` | Earlier generated draft, superseded by the gold-logo reference |
| `scenes/ui/salon_map_backdrop.gd` | Code-native map road, margin decorations and locks |
| `assets/fonts/Fredoka.ttf` | Unmodified [Google Fonts Fredoka](https://github.com/google/fonts/tree/main/ofl/fredoka); accompanying SIL OFL license |
| `assets/fonts/Nunito.ttf` | Unmodified [Google Fonts Nunito](https://github.com/google/fonts/tree/main/ofl/nunito); accompanying SIL OFL license |

Title SHA-256: `13a6aba9cdf041e7ca0e1dae3bffa623bc694e480cded74e3d73a7e27b24897d`.
Texture import: lossless, no mipmaps, linear UI filtering. Original character portraits
are used for the map marker. The source-art directory is excluded from Godot by `.gdignore`.
Only the game logo is baked into title art; buttons, labels, stage numbers, locks, progress
and input are native controls/drawing. Font variation axes use integer OpenType tags.

The 11 opening panels in the overview remain storyboard references. This UI pass does
not present thumbnail crops as finished cutscene assets or claim an animated opening.

## Generation prompt

Tool: built-in `image_gen.imagegen`, opaque output, latest overview as reference image.

> Create ONE finished 16:9 1920x1080 game title-screen background illustration derived faithfully from the TOP LEFT title-main-menu panel of this user's AI-generated asset-library reference. The overview is a reference, not an edit target to reproduce: exclude the library sheet, captions, map, opening thumbnails and all review text. Preserve the newer GOLD logo composition and airborne characters, not the older pink-logo standing-handshake composition. Warm polished cute 2D cartoon salon, thick dark-purple outlines, soft cel shading, cream peach walls, lavender panels, gleaming blue mirrors, coral-red barber chairs, warm brown drawers, teal/purple hair-product bottles, little plants, pink-and-cream checker floor. A clear two-line logo in the UPPER LEFT says exactly 'Oh No My Hair!' in large playful rounded GOLD/YELLOW bubble letters with cream highlights and thick dark-purple outlines, matching the reference. The logo occupies x=6%-46%, y=7%-42%. At the RIGHT half, x=50%-90%, y=12%-83%, the two ORIGINAL friends joyfully leap while holding hands: pink Twin-Tails above/right, blue spiky Pompadour below/left. Cream oval faces, two dark oval eyes, NO MOUTHS, glossy voluminous hair, dark purple thin stick arms and legs, oval hands and feet. Match the reference identities, action direction and silhouette; no clothes or extra characters. Include a few floating pink and blue hair clippings across the lower floor as in the reference. Leave a clean quiet area on the LEFT UNDER THE LOGO at x=10%-43%, y=48%-78% with subdued salon wall/chair behind it so native Start Game and About buttons can be placed there. Do NOT draw those buttons, any menu lettering, icons or UI controls. The only text in the image is the gold game logo. No watermark. This is production artwork, not a menu mockup, and interactive controls will be drawn by Godot.

The tool returned 1672Ã—941 rather than the requested 1920Ã—1080. Its near-16:9 composition
was inspected and kept at its original resolution; Godot scales it to the 1280Ã—720 viewport.

## Verification

Headless tests cover title-to-map-to-game flow, latest-stage selection, locked-stage
rejection, mystery naming, Back/Esc and focus containment, plus the campaign regression
suites. GPU renders cover cover/map, help, HUD, pause, death, results and chairs, with
title/map checks at 1280Ã—720, 960Ã—540 and a 1280Ã—960 window (letterboxed game viewport).
Review captures are in `.godot/poster-shots/` and logs in `.godot/poster-*.log`.
