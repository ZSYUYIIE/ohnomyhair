class_name MainMenu
extends Control
## Illustrated salon cover; the escape route lives in a separate chapter sheet.
const Guide := preload("res://scenes/ui/controls_guide.gd")
const DESCRIPTIONS := ["Find the service route together", "Turn the robot's scissors against it",
	"Escape through the wash room", "Face the runaway assistant. Reach the back door."]
const MapBackdrop := preload("res://scenes/ui/salon_map_backdrop.gd")
var _play_buttons: Array[Button] = []
var _menu_buttons: Array[Button] = []
var _controls: Control
var _controls_button: Button
var _start_button: Button
var _chapters_button: Button
var _chapters: Control
var _chapter_back: Button
var _help_from_chapters := false
var _selected_chapter := 0
var _map_play: Button
var _map_title: Label
var _map_detail: Label
var _map_backdrop: Control
var _markers: Array[TextureRect] = []

func _ready() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.get_theme()
	var art := TextureRect.new()
	art.texture = preload("res://assets/art/ui/poster/title_scene_gold.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	var cover := Control.new()
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cover)
	var col := VBoxContainer.new()
	col.position = Vector2(145, 365)
	col.size = Vector2(345, 155)
	col.add_theme_constant_override("separation", 16)
	cover.add_child(col)
	_start_button = _button("▶  Start Game", _open_chapters)
	_start_button.custom_minimum_size = Vector2(345, 64)
	_start_button.add_theme_font_size_override("font_size", 30)
	_start_button.add_theme_stylebox_override("normal", UiTheme.card(UiTheme.GOLD, UiTheme.INK, 4, 30, 12))
	col.add_child(_start_button)
	_menu_buttons.append(_start_button)
	_chapters_button = _start_button
	_controls_button = _button("About", _toggle_controls)
	_controls_button.custom_minimum_size.y = 52
	col.add_child(_controls_button)
	_menu_buttons.append(_controls_button)
	var quit_button := _button("Quit", func(): get_tree().quit())
	quit_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	quit_button.offset_left = -134
	quit_button.offset_right = -30
	quit_button.offset_top = -68
	quit_button.offset_bottom = -24
	cover.add_child(quit_button)
	_menu_buttons.append(quit_button)
	_build_chapters()
	_controls = Guide.new()
	add_child(_controls)
	_controls.closed.connect(_guide_closed)
	_controls.hide()
	UiTheme.focus_loop(_menu_buttons)
	_focus_latest()

func _build_chapters() -> void:
	_chapters = Control.new()
	_chapters.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_chapters)
	var paper := ColorRect.new()
	paper.color = UiTheme.CREAM
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_chapters.add_child(paper)
	_map_backdrop = MapBackdrop.new()
	_map_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in Progress.LEVELS.size(): _map_backdrop.unlocked.append(Progress.is_unlocked(i))
	_chapters.add_child(_map_backdrop)
	var title := UiTheme.heading("Salon Map", 52)
	title.position = Vector2(65, 42)
	_chapters.add_child(title)
	_chapter_back = _button("Back", _close_chapters)
	_chapter_back.position = Vector2(1100, 48)
	_chapter_back.custom_minimum_size = Vector2(110, 44)
	_chapters.add_child(_chapter_back)
	for i in Progress.LEVELS.size():
		var at: Vector2 = MapBackdrop.STOPS[i]
		var button := _button("?" if i == 3 and not Progress.is_cleared(i) else str(i + 1), _select_chapter.bind(i))
		button.disabled = not Progress.is_unlocked(i)
		button.position = at - Vector2(56, 30)
		button.custom_minimum_size = Vector2(112, 66)
		button.add_theme_font_size_override("font_size", 34)
		var locked_style := UiTheme.card(Color("d8c6e5"), UiTheme.INK, 3, 32, 8)
		if i == 3:
			button.position = at - Vector2(43, 60)
			button.custom_minimum_size = Vector2(86, 98)
			locked_style.bg_color = Color("79568d")
			locked_style.corner_radius_bottom_left = 10
			locked_style.corner_radius_bottom_right = 10
			button.add_theme_color_override("font_disabled_color", UiTheme.CREAM)
		button.add_theme_stylebox_override("disabled", locked_style)
		button.tooltip_text = "Finish every earlier stage to unlock" if button.disabled else "Choose this stage"
		_chapters.add_child(button)
		_play_buttons.append(button)
		var tag := PanelContainer.new()
		tag.position = at + Vector2(-120, 44)
		tag.custom_minimum_size = Vector2(240, 38)
		tag.add_theme_stylebox_override("panel", UiTheme.card(UiTheme.CREAM, UiTheme.INK, 3, 14, 4))
		_chapters.add_child(tag)
		var label := UiTheme.heading(_chapter_name(i), 19)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.add_child(label)
	for hair in ["twin_tails", "pompadour"]:
		var marker := TextureRect.new()
		marker.texture = load("res://assets/art/characters/portraits/%s.png" % hair)
		marker.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		marker.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		marker.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.size = Vector2(74, 94)
		_chapters.add_child(marker)
		_markers.append(marker)
	var panel := PanelContainer.new()
	panel.position = Vector2(55, 594)
	panel.size = Vector2(1170, 92)
	panel.add_theme_stylebox_override("panel", UiTheme.card(UiTheme.CREAM, UiTheme.INK, 4, 22, 13))
	_chapters.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	panel.add_child(row)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	row.add_child(col)
	_map_title = UiTheme.heading("", 30)
	col.add_child(_map_title)
	_map_detail = UiTheme.label("", 17)
	col.add_child(_map_detail)
	_map_play = _button("Play  ▶", func(): play(_selected_chapter))
	_map_play.custom_minimum_size = Vector2(185, 54)
	_map_play.add_theme_font_size_override("font_size", 28)
	_map_play.add_theme_stylebox_override("normal", UiTheme.card(UiTheme.GOLD, UiTheme.INK, 3, 24, 10))
	row.add_child(_map_play)
	_select_chapter(_latest_unlocked())
	_chapters.hide()

func _chapter_name(index: int) -> String:
	return "???" if index == 3 and (not Progress.is_unlocked(index) or not Progress.is_cleared(index)) else Progress.LEVELS[index].title

func _select_chapter(index: int) -> void:
	if not Progress.is_unlocked(index): return
	_selected_chapter = index
	_map_title.text = _chapter_name(index)
	_map_detail.text = "Stage %d / %d" % [index + 1, Progress.LEVELS.size()]
	if Progress.is_cleared(index):
		_map_detail.text += "  ·  Best %s  ·  %d deaths" % [Progress.format_time(Progress.best_time(index)), Progress.best_deaths(index)]
	for i in _play_buttons.size():
		var style := UiTheme.card(UiTheme.GOLD if i == index else UiTheme.LILAC, UiTheme.INK, 4, 36, 8)
		if i == 3:
			style.corner_radius_bottom_left = 10
			style.corner_radius_bottom_right = 10
		_play_buttons[i].add_theme_stylebox_override("normal", style)
	for i in _markers.size():
		_markers[i].position = MapBackdrop.STOPS[index] + Vector2(-73 + i * 66, -128)
	_map_backdrop.selected = index
	_map_backdrop.queue_redraw()

func _latest_unlocked() -> int:
	for i in range(Progress.LEVELS.size() - 1, -1, -1):
		if Progress.is_unlocked(i): return i
	return 0

func _focus_latest() -> void:
	UiTheme.focus_if_visible.call_deferred(_play_buttons[_latest_unlocked()] if _chapters.visible else _start_button)

func _open_chapters() -> void:
	if _controls.visible: return
	for b in _menu_buttons: b.focus_mode = Control.FOCUS_NONE
	_chapters.show()
	_select_chapter(_latest_unlocked())
	var enabled: Array[Button] = []
	for b in _play_buttons:
		if not b.disabled: enabled.append(b)
	enabled.append_array([_map_play, _chapter_back])
	UiTheme.focus_loop(enabled)
	for i in _play_buttons.size():
		var b := _play_buttons[i]
		if b.disabled: continue
		for side in [["left", i - 1], ["right", i + 1]]:
			var at: int = side[1]
			if at >= 0 and at < _play_buttons.size() and not _play_buttons[at].disabled:
				b.set("focus_neighbor_" + side[0], _play_buttons[at].get_path())
		b.focus_neighbor_bottom = _map_play.get_path()
		b.focus_neighbor_top = _chapter_back.get_path()
	_focus_latest()

func _close_chapters() -> void:
	_chapters.hide()
	for b in _menu_buttons: b.focus_mode = Control.FOCUS_ALL
	UiTheme.focus_if_visible.call_deferred(_chapters_button)

func play(index: int) -> void:
	if index >= 0 and index < Progress.LEVELS.size() and Progress.is_unlocked(index) and not _controls.visible:
		get_tree().change_scene_to_file(Progress.LEVELS[index].path)

func _toggle_controls() -> void:
	if _controls.visible:
		_controls.dismiss()
		return
	_help_from_chapters = _chapters.visible
	for b in _menu_buttons + _play_buttons + [_chapter_back]: b.focus_mode = Control.FOCUS_NONE
	_controls.open()

func _guide_closed() -> void:
	for b in _menu_buttons + _play_buttons + [_chapter_back]: b.focus_mode = Control.FOCUS_ALL
	if _help_from_chapters:
		_open_chapters()
	else:
		UiTheme.focus_if_visible.call_deferred(_controls_button)

func _unhandled_input(event: InputEvent) -> void:
	if _chapters.visible and not _controls.visible and event.is_action_pressed("ui_cancel"):
		_close_chapters()
		get_viewport().set_input_as_handled()

func _button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 44
	b.pressed.connect(action)
	return b
