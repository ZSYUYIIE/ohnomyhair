# Scissors cursor

Two original SVG icons in `assets/art/ui/cursor/`, authored for this project:
`scissors_open.svg` and `scissors_closed.svg`. Both are transparent 48×48 images
with gold blades/handles, cream highlights and the UI's dark purple outline.

The fixed blade tip at (4, 6) is the hotspot in both poses. Left mouse down closes
the scissors; release opens them. The persistent `ScissorsCursor` autoload works
across scene changes and paused menus, and resets the pose when focus is lost.
Both the arrow and button-hover cursor shapes use the scissors.

The implementation uses Godot's [native custom cursor API](https://docs.godotengine.org/en/stable/tutorials/inputs/custom_mouse_cursor.html).
Textures change only when the pose changes.
