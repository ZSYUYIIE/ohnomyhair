class_name UiTheme
extends RefCounted
## Shared look for menus and the HUD: cream salon cards with walnut borders,
## pink focus ring (keyboard navigation must be visible).

const INK := Color("4a3426")
const CREAM := Color("fff7ec")
const WALNUT := Color("6b432c")
const PINK := Color("ff5fa2")
const BLUE := Color("3a8fd6")
const GOLD := Color("f1c40f")

static var _theme: Theme


static func get_theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font_size = 20
	t.set_stylebox("panel", "PanelContainer", card(CREAM, WALNUT))
	t.set_color("font_color", "Label", INK)

	t.set_stylebox("normal", "Button", card(Color("f4e3cf"), WALNUT, 2, 8, 18))
	t.set_stylebox("hover", "Button", card(Color("ffe3ef"), WALNUT, 2, 8, 18))
	t.set_stylebox("pressed", "Button", card(Color("ffc1dc"), WALNUT, 2, 8, 18))
	t.set_stylebox("disabled", "Button", card(Color("e6ddd2"), Color("b9a998"), 2, 8, 18))
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.set_border_width_all(4)
	focus.border_color = PINK
	focus.set_corner_radius_all(10)
	focus.set_expand_margin_all(3)
	t.set_stylebox("focus", "Button", focus)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(c, "Button", INK)
	t.set_color("font_disabled_color", "Button", Color("a3968a"))
	t.set_font_size("font_size", "Button", 22)
	_theme = t
	return t


## Rounded card style used by panels, buttons and HUD plates.
static func card(bg: Color, border: Color, border_width := 3, radius := 12, pad := 14) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_width)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(pad)
	s.shadow_color = Color(0, 0, 0, 0.18)
	s.shadow_size = 4
	s.shadow_offset = Vector2(0, 3)
	return s


static func label(text: String, size := 20, color := INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
