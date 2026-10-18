# Supplied Salon Map integration

Source: `C:/Users/drdot/Downloads/SalonMap_Godot4_GameJam_Assets/SalonMap_Godot4_Jam`.
The Chinese README was read before integrating. Its original text, editable SVGs,
palette, asset manifest and source notes are preserved in `art_src/ui/salon_map`.

The original `map_clean.png` and transparent UI PNGs are under
`assets/art/ui/salon_map`. The pack describes the background as AI-assisted artwork.
Its map, road, furniture, question-mark door and title remain baked together.
Numbers, locks, completion checks, names, records, Play and Back are
separate live controls.

The built-in image editing tool removed the baked friends and made all four platforms
neutral lavender in `map_neutral.png`. `map_gold_platforms.png` is an aligned color
variant; four small runtime AtlasTexture regions reveal gold only at the selected
destination, retaining furniture occlusion. The original image is preserved.
`friends_marker.png` separates the supplied pink / blue pair onto transparent alpha.
A runtime shader drops the faint cutout halo without changing the source bitmap.

The pair moves between feet anchors on the near half of the four stage ellipses.
A 0.32-second arcing move and small landing bounce acknowledge a new selection.
Marker size follows the existing map perspective. Repeated refreshes do not restart
the animation; a new selection cancels the previous tween. Locked stops cannot move
the pair or turn gold. Hovering alone never changes the gold platform.

`scenes/ui/salon_map.gd` uses the supplied 1672×941 layout coordinates on one uniformly
scaled Control canvas, centered within the current viewport. Its artwork and mouse
regions inherit exactly the same transform. This preserves the gameplay project's
1280×720 display configuration and allows uncropped map art at other aspect ratios.
The information panel and shortcut line use a VBox with a reserved gap.

Integration uses the existing `Progress` store, four real campaign scenes and the
main menu's Story / help navigation. No demo completion button, second save file,
demo title overlay or pack project settings were imported. The finale keeps the
game's mystery name until cleared. Existing Fredoka / Nunito fonts keep the UI
consistent with the rest of the game; the pack's DejaVu font is not needed.

Illustrations and label pills select destinations. Locked illustrations show an
unlock explanation; disabled labels remain outside the keyboard focus loop. The
buttons use the supplied normal / hover / pressed artwork and pointer feedback.
The friends, gold platform and label show the selected stage; the extra yellow arc
and pink label focus frame are removed. All illustrated map buttons, including
Story, Rooms, Back and Play, now use the supplied skins and focus pop without an
extra surrounding frame. Other menus keep ink hover borders and gold keyboard focus.
Back, help, number keys,
arrows / Tab, Enter / Space activation and P to play retain their existing behavior.

Story replaces the old Opening button and offers both CGs (ending requires all
chapters cleared). After campaign completion, Rooms lists the selected chapter's
authored rooms. Both collections use native modal buttons with contained keyboard
focus, Esc / Back navigation and preserved map selection. Single-room replays
never update chapter records or trigger the automatic ending.

Validation: `tests/test_ui_layout.gd` passes 73 checks with real window resizing and mouse clicks at
960×540, 1280×720, 1600×900, 1920×1080 and 1280×800. It also checks fresh-save locks,
the mystery label, footer spacing, records and whole-room HUD framing. Captures:
`.godot/ui-layout`. Menu and navigation suites cover saved unlocks and real level
launches, including saves with out-of-order chapter records. Four selected-stage
captures also show marker placement and platform colors; rapid selections settle
at the final destination. Story and room-picker layouts are captured at all five
sizes. Menu / navigation suites add 105 passing checks; postgame tests cover all
twelve room entries, replay results, retries, save flags and completion locks.
