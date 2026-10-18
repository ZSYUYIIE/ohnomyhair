class_name UiTheme
extends RefCounted
## Shared look for menus and the HUD: cream salon cards with walnut borders,
## pink focus ring (keyboard navigation must be visible).

const INK := Color("2b2140")
const CREAM := Color("fff5e3")
const WALNUT := Color("34263f")
const MUTED := Color("786378")
const PINK := Color("f94b9c")
const BLUE := Color("168ee1")
const GOLD := Color("ffda47")
const PEACH := Color("f9d9b3")
const LILAC := Color("dcc8df")
const WOOD := Color("ae755b")

static var _theme: Theme
static var _body_font: FontVariation
static var _heading_font: FontVariation


static func body_font() -> Font:
	if not _body_font:
		_body_font = FontVariation.new()
		_body_font.base_font = preload("res://assets/fonts/Nunito.ttf")
		_body_font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 750.0}
	return _body_font


static func heading_font() -> Font:
	if not _heading_font:
		_heading_font = FontVariation.new()
		_heading_font.base_font = preload("res://assets/fonts/Fredoka.ttf")
		_heading_font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 600.0}
	return _heading_font


static func get_theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = body_font()
	t.default_font_size = 20
	t.set_stylebox("panel", "PanelContainer", card(CREAM, WALNUT))
	t.set_color("font_color", "Label", INK)

	t.set_stylebox("normal", "Button", card(CREAM, WALNUT, 3, 18, 10))
	t.set_stylebox("hover", "Button", card(Color("ffe1ef"), WALNUT, 3, 18, 10))
	t.set_stylebox("pressed", "Button", card(Color("ffb9d8"), WALNUT, 3, 18, 10))
	t.set_stylebox("disabled", "Button", card(Color("e8ded6"), Color("ae99aa"), 2, 18, 10))
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.set_border_width_all(4)
	focus.border_color = GOLD
	focus.set_corner_radius_all(20)
	focus.set_expand_margin_all(3)
	t.set_stylebox("focus", "Button", focus)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(c, "Button", INK)
	t.set_color("font_disabled_color", "Button", Color("776b78"))
	t.set_font_size("font_size", "Button", 22)
	t.set_font("font", "Button", heading_font())
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
	s.shadow_color = Color(0.20, 0.12, 0.24, 0.25)
	s.shadow_size = 0
	s.shadow_offset = Vector2(0, 5)
	return s


static func label(text: String, size := 20, color := INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func heading(text: String, size := 32, color := INK) -> Label:
	var l := label(text, size, color)
	l.add_theme_font_override("font", heading_font())
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
