# Asset Library v1: title, Salon Map and opening

The teammate bundle supplied by the user on 2026-10-18 replaces the generated title
draft. The source folder is `C:/Users/drdot/Downloads/ohnomyhair_asset_library_v1`.
The project contains every runtime asset it needs; it does not depend on that Downloads path.

## Runtime integration

- `assets/art/ui/poster/title_main_menu.png`: exact 1280×720 supplied title preview.
  Its logo and Start Game / About lettering are baked in. Transparent native Buttons
  align with those painted buttons, adding focus/hover feedback without duplicate text.
  Quit remains a native button. A future localization pass needs separated title layers.
- Start Game opens a native four-stop Salon Map. The teammate map is a static mockup
  with locked progress baked in, so native controls/drawing implement its road, labels,
  stage selection, padlocks and Play footer. Every earlier chapter must be cleared.
  The final stop remains `?` / `???` until cleared; no boss illustration is shown.
- `map_friends.png` is the exact supplied earlier transparent pair layer. An AtlasTexture
  selects its occupied region (412,280,456,255); both friends move to the selected stop.
  This reuses the standing pair intentionally, rather than treating it as a new-menu layer.
- Map Play starts the opening on a fresh save, then loads Fresh Cut. Existing clears
  count as having seen the opening. Natural completion and skipping persist
  `story/opening_seen` in the existing save without changing chapter records.
- `assets/art/opening/`: all 11 clean supplied panels, each 1280×720. The 39-second
  timeline and English subtitles match the teammate JSON. Transitions are included
  in each shot's duration. Wide shots push in at most 2.5%; close-ups keep their framing.
  Subtitles use the bottom 140 px. Any key/click/controller button skips after a short
  input guard so the opening Play click cannot skip it accidentally.
- About opens the credits tab (GameJamPlus 26/27 / NPC Union / Singapore), with the
  existing controls, combos and story help available alongside it.
- HUD, pause, death, results, help, chair selection and boss bar share cream panels,
  purple outlines, gold highlights and rounded fonts. Gameplay art is unchanged.

## Provenance and imports

`poster_ui_manifest.json` records runtime paths, source paths, dimensions and SHA-256.
The supplied image hashes were checked against the teammate manifest, and the 13
runtime copies are byte-for-byte identical. The original design metadata, timeline,
SRT, generation prompts and README are retained under `docs/art/teammate_library_v1`.
Those files describe the teammate delivery, not the current implementation status.
The source specification calls the final chapter The Barber; the game's story name
remains The Assistant, with the stable save ID `the_barber` retained.

The map reference is archived under `art_src/ui/teammate_library_v1`. Generated pink
and gold draft titles are retained under `art_src/ui`, excluded from Godot imports;
`generated_drafts.md` records their earlier prompt and provenance. Unused native-size
previews, optional SNIP variants and other reusable slices remain in the supplied
bundle and are not shipped as runtime textures.

Texture import: lossless, no mipmaps, linear filtering. Godot uses a 1280×720 reference
viewport and letterboxes other aspect ratios. The opening has no supplied audio;
this implementation is illustrated panels with subtle motion, subtitles and transitions.

Fonts are unmodified [Fredoka](https://github.com/google/fonts/tree/main/ofl/fredoka)
and [Nunito](https://github.com/google/fonts/tree/main/ofl/nunito) from Google Fonts.
Their accompanying SIL OFL licenses are under `assets/fonts`. Numeric OpenType tags
select the intended variable-font weights. License wording is preserved.

## Verification

`tests/test_opening.gd` checks source timeline parity, all 11 frames, exact boundaries,
natural completion, initial-click protection, keyboard/mouse/controller skipping,
persisted seen state, existing-save continuation and locked-destination rejection.
`tests/test_menu.gd` covers cover → map → Play, map selection, locks, mystery naming,
Back/Esc and keyboard focus, plus campaign and HUD regressions.

GPU captures include every opening panel, cover/map at 1280×720 and 960×540, the
letterboxed 1280×960 window, credits/help, HUD, pause, death, results and chairs.
Review captures are in `.godot/poster-shots/`; logs are `.godot/teammate-*.log`.
