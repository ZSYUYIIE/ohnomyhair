class_name MainMenu
extends Control
## Illustrated salon cover; the escape route lives in a separate chapter sheet.
const Guide := preload("res://scenes/ui/controls_guide.gd")
const Opening := preload("res://scenes/ui/opening_cutscene.gd")
var _play_buttons: Array[Button] = []
var _menu_buttons: Array[Button] = []
var _controls: Control
var _controls_button: Button
var _start_button: Button
var _opening_button: Button
var _chapters_button: Button
var _chapters: Control
var _chapter_back: Button
var _help_from_chapters := false
var _selected_chapter := 0
var _map_play: Button
var _map_title: Label
var _map_detail: Label
var _card_states: Array[Label] = []

func _ready() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.get_theme()
	Sound.music("menu")
	var art := TextureRect.new()
	art.texture = preload("res://assets/art/ui/poster/title_interactive_backdrop.png")
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
	_start_button = _button("▶  Start Game", _open_chapters)
	_start_button.position = Vector2(94, 374)
	_start_button.size = Vector2(382, 76)
	_start_button.add_theme_font_size_override("font_size", 32)
	UiTheme.primary(_start_button)
	cover.add_child(_start_button)
	_menu_buttons.append(_start_button)
	_chapters_button = _start_button
	_controls_button = _button("About & controls", _toggle_controls)
	_controls_button.position = Vector2(112, 472)
	_controls_button.size = Vector2(346, 62)
	cover.add_child(_controls_button)
	_menu_buttons.append(_controls_button)
	_opening_button = _button("Watch opening", _watch_opening)
	_opening_button.position = Vector2(125, 554)
	_opening_button.size = Vector2(320, 50)
	cover.add_child(_opening_button)
	_menu_buttons.append(_opening_button)
	var keys := UiTheme.label("↑ ↓ / Tab  Navigate   ·   Enter  Choose   ·   I  Opening   ·   F1 / H  Help", 16, UiTheme.CREAM)
	keys.position = Vector2(58, 674)
	keys.add_theme_color_override("font_outline_color", UiTheme.INK)
	keys.add_theme_constant_override("outline_size", 6)
	keys.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.add_child(keys)
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
	var salon := TextureRect.new()
	salon.texture = preload("res://assets/art/salon_v2/landing_background.png")
	salon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	salon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	salon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	salon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chapters.add_child(salon)
	var shade := ColorRect.new()
	shade.color = Color(0.12, 0.07, 0.21, 0.86)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_chapters.add_child(shade)
	var title := UiTheme.heading("Find your way out", 48, UiTheme.CREAM)
	title.position = Vector2(54, 36)
	_chapters.add_child(title)
	var intro := UiTheme.label("ONE SALON. TWO FRIENDS.  Choose a chapter to escape together.", 20, Color("dbc9e7"))
	intro.position = Vector2(57, 103)
	_chapters.add_child(intro)
	_chapter_back = _button("‹  Back", _close_chapters)
	_chapter_back.position = Vector2(1090, 48)
	_chapter_back.size = Vector2(132, 56)
	_chapters.add_child(_chapter_back)
	var previews := [preload("res://assets/art/ui/chapters/fresh_cut.png"),
		preload("res://assets/art/ui/chapters/return_to_sender.png"),
		preload("res://assets/art/ui/chapters/wash_blow_dry.png"),
		preload("res://assets/art/ui/chapters/mystery.png")]
	for i in Progress.LEVELS.size():
		var button := _button("", _select_chapter.bind(i))
		button.position = Vector2(54 + i * 298, 180)
		button.size = Vector2(278, 351)
		button.clip_contents = true
		button.disabled = not Progress.is_unlocked(i)
		button.tooltip_text = "Select " + _chapter_name(i) if not button.disabled else "Complete the previous chapter first"
		button.add_theme_stylebox_override("disabled", UiTheme.button_skin(Color("b9a9bd")))
		_chapters.add_child(button)
		_play_buttons.append(button)
		button.focus_entered.connect(_select_chapter.bind(i))
		var frame := Control.new()
		frame.name = "PreviewFrame"
		frame.position = Vector2(12, 12)
		frame.size = Vector2(254, 166)
		frame.clip_contents = true
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(frame)
		var image := TextureRect.new()
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_SCALE
		image.texture = previews[i]
		image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		image.modulate = Color(0.53, 0.46, 0.58) if button.disabled else Color.WHITE
		frame.add_child(image)
		var step := UiTheme.label("CHAPTER  %02d" % [i + 1], 16, UiTheme.MUTED)
		step.position = Vector2(18, 194)
		step.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(step)
		var name_label := UiTheme.heading(_chapter_name(i), 25)
		name_label.position = Vector2(18, 221)
		name_label.size = Vector2(245, 68)
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(name_label)
		var state := UiTheme.heading("", 20)
		state.position = Vector2(18, 296)
		state.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(state)
		_card_states.append(state)
		if button.disabled:
			var locked := UiTheme.heading("LOCKED", 25, UiTheme.CREAM)
			locked.position = Vector2(76, 80)
			locked.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(locked)
	var panel := PanelContainer.new()
	panel.position = Vector2(54, 577)
	panel.size = Vector2(1172, 104)
	panel.add_theme_stylebox_override("panel", UiTheme.card(UiTheme.CREAM, UiTheme.INK, 3, 22, 15))
	_chapters.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	panel.add_child(row)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	_map_title = UiTheme.heading("", 30)
	col.add_child(_map_title)
	_map_detail = UiTheme.label("", 18, UiTheme.MUTED)
	col.add_child(_map_detail)
	_map_play = _button("Play chapter  ▶", func(): play(_selected_chapter))
	_map_play.custom_minimum_size = Vector2(250, 64)
	UiTheme.primary(_map_play)
	row.add_child(_map_play)
	var keys := UiTheme.label("← → / Tab  Select   ·   1–4  Chapter   ·   P  Play   ·   Esc  Back   ·   F1 / H  Help", 16, Color("e7d8ef"))
	keys.position = Vector2(59, 692)
	keys.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chapters.add_child(keys)
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
		_map_detail.text += "  Â·  Best %s  Â·  %d deaths" % [Progress.format_time(Progress.best_time(index)), Progress.best_deaths(index)]
	for i in _play_buttons.size():
		var button := _play_buttons[i]
		button.add_theme_stylebox_override("normal", UiTheme.button_skin(UiTheme.GOLD if i == index else UiTheme.CREAM))
		button.add_theme_stylebox_override("hover", UiTheme.button_skin(Color("fff0af"), true))
		button.add_theme_stylebox_override("pressed", UiTheme.button_skin(Color("edc95d"), false, true))
		_card_states[i].text = "Complete chapter %d" % i if button.disabled else ("Selected  ✓" if i == index else "Choose chapter  →")
		_card_states[i].add_theme_color_override("font_color", UiTheme.MUTED if button.disabled else UiTheme.INK)

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
		if not Progress.has_seen_opening():
			var opening := Opening.new()
			opening.target_index = index
			get_tree().root.add_child(opening)
			get_tree().current_scene = opening
			queue_free()
		else:
			get_tree().change_scene_to_file(Progress.LEVELS[index].path)

func _watch_opening() -> void:
	if _controls.visible or _chapters.visible: return
	var opening := Opening.new()
	opening.return_to_menu = true
	get_tree().root.add_child(opening)
	get_tree().current_scene = opening
	queue_free()

func _toggle_controls(tab: int = 3) -> void:
	if _controls.visible:
		_controls.dismiss()
		return
	_help_from_chapters = _chapters.visible
	for b in _menu_buttons + _play_buttons + [_chapter_back, _map_play]: b.focus_mode = Control.FOCUS_NONE
	_controls.open(tab)

func _guide_closed() -> void:
	for b in _menu_buttons + _play_buttons + [_chapter_back, _map_play]: b.focus_mode = Control.FOCUS_ALL
	if _help_from_chapters:
		_open_chapters()
	else:
		UiTheme.focus_if_visible.call_deferred(_controls_button)

func _unhandled_input(event: InputEvent) -> void:
	if _controls.visible: return
	if event.is_action_pressed("show_help"):
		_toggle_controls(4)
		get_viewport().set_input_as_handled()
		return
	if not _chapters.visible and event.is_action_pressed("menu_opening"):
		get_viewport().set_input_as_handled()
		_watch_opening()
		return
	if _chapters.visible:
		if event.is_action_pressed("menu_play"):
			get_viewport().set_input_as_handled()
			play(_selected_chapter)
			return
		for i in _play_buttons.size():
			if event.is_action_pressed("chapter_%d" % [i + 1]):
				if not _play_buttons[i].disabled:
					_select_chapter(i)
					_play_buttons[i].grab_focus()
				get_viewport().set_input_as_handled()
				return
	if _chapters.visible and not _controls.visible and event.is_action_pressed("ui_cancel"):
		_close_chapters()
		get_viewport().set_input_as_handled()

func _button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 44
	UiTheme.wire_button(b)
	b.pressed.connect(action)
	return b
