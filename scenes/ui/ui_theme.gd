class_name UiTheme
extends RefCounted
## Shared look for menus and the HUD: cream salon cards with walnut borders,
## pink focus ring (keyboard navigation must be visible).

const INK := Color("2b2140")
const CREAM := Color("fff8ef")
const WALNUT := Color("51405d")
const MUTED := Color("716578")
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

	t.set_stylebox("normal", "Button", card(Color("f5e9de"), WALNUT, 2, 10, 10))
	t.set_stylebox("hover", "Button", card(Color("ffe3ef"), WALNUT, 2, 10, 10))
	t.set_stylebox("pressed", "Button", card(Color("ffc1dc"), WALNUT, 2, 10, 10))
	t.set_stylebox("disabled", "Button", card(Color("e6ddd2"), Color("b9a998"), 2, 10, 10))
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.set_border_width_all(4)
	focus.border_color = PINK
	focus.set_corner_radius_all(10)
	focus.set_expand_margin_all(3)
	t.set_stylebox("focus", "Button", focus)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(c, "Button", INK)
	t.set_color("font_disabled_color", "Button", Color("776b78"))
	t.set_font_size("font_size", "Button", 22)
	t.set_stylebox("panel", "TabContainer", card(CREAM, Color("c5b9c5"), 1, 10, 4))
	t.set_stylebox("tab_selected", "TabBar", card(Color("f9e39b"), WALNUT, 2, 8, 10))
	t.set_stylebox("tab_unselected", "TabBar", card(Color("eee6e1"), Color("c5b9c5"), 1, 8, 10))
	t.set_stylebox("focus", "TabBar", focus)
	t.set_color("font_selected_color", "TabBar", INK)
	t.set_color("font_unselected_color", "TabBar", MUTED)
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


## Keep keyboard navigation inside the visible menu.
static func focus_loop(buttons: Array[Button]) -> void:
	for i in buttons.size():
		var b := buttons[i]
		var previous := buttons[(i - 1 + buttons.size()) % buttons.size()].get_path()
		var next := buttons[(i + 1) % buttons.size()].get_path()
		b.focus_previous = previous
		b.focus_next = next
		b.focus_neighbor_top = previous
		b.focus_neighbor_bottom = next
		b.focus_neighbor_left = previous
		b.focus_neighbor_right = next


static func focus_if_visible(button: Button) -> void:
	if is_instance_valid(button) and button.is_inside_tree() and button.is_visible_in_tree() and not button.disabled:
		button.grab_focus()
