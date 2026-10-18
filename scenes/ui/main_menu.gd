class_name MainMenu
extends Control
## Illustrated salon cover; the escape route lives in a separate chapter sheet.
const Guide := preload("res://scenes/ui/controls_guide.gd")
const Opening := preload("res://scenes/ui/opening_cutscene.gd")
const Ending := preload("res://scenes/ui/ending_cutscene.gd")
const COVER := preload("res://assets/art/ui/poster/title_cover.png")
## Painted pills on the cover, in cover pixels; the cut-out sprites sit exactly on top.
const START_RECT := Rect2(140, 469, 538, 153)
const ABOUT_RECT := Rect2(176, 615, 464, 127)
const SalonMap := preload("res://scenes/ui/salon_map.gd")
var _play_buttons: Array[Button] = []
var _menu_buttons: Array[Button] = []
var _controls: Control
var _controls_button: Button
var _start_button: Button
var _opening_button: Button
var _chapters_button: Button
var _quit_confirm: Control
var _quit_stay: Button
var _quit_return: Button
var _chapters: Control
var _chapter_back: Button
var _help_from_chapters := false
var _selected_chapter := 0
var _map_play: Button
var _map_title: Label
var _map_detail: Label
var _map_view: Control
var _chapter_footer: VBoxContainer
var _chapter_shortcuts: Label
var _collection: Control
var _collection_buttons: Array[Button] = []
var _collection_return: Control
var _collection_kind := ""

func _ready() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.get_theme()
	Sound.music("menu")
	var art := TextureRect.new()
	art.texture = COVER
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
	_start_button = _cover_button(preload("res://assets/art/ui/poster/title_button_start.png"), START_RECT, "Start Game", _enter_game)
	cover.add_child(_start_button)
	_menu_buttons.append(_start_button)
	_chapters_button = _start_button
	_controls_button = _cover_button(preload("res://assets/art/ui/poster/title_button_about.png"), ABOUT_RECT, "About", _toggle_controls)
	cover.add_child(_controls_button)
	_menu_buttons.append(_controls_button)
	resized.connect(_place_cover_buttons)
	_place_cover_buttons()
	# A browser tab can't be quit from inside the page, so only desktop builds offer it.
	if not OS.has_feature("web"):
		var quit_button := _quit_button()
		cover.add_child(quit_button)
		_menu_buttons.append(quit_button)
	_build_chapters()
	_controls = Guide.new()
	add_child(_controls)
	_controls.closed.connect(_guide_closed)
	_controls.hide()
	if not OS.has_feature("web"):
		_build_quit_confirm()
	UiTheme.focus_loop(_menu_buttons)
	_focus_latest()

## A painted pill from the cover, cut out so it can pop on hover and focus.
func _cover_button(texture: Texture2D, rect: Rect2, label: String, action: Callable) -> Button:
	var b := Button.new()
	b.name = label.replace(" ", "")
	b.flat = true
	b.set_meta("cover_rect", rect)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var art := TextureRect.new()
	art.texture = texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(art)
	UiTheme.wire_button(b, 1.06)
	b.pressed.connect(action)
	return b

## Keep the cut-outs glued to the painted pills however the cover is cropped.
func _place_cover_buttons() -> void:
	var image := Vector2(COVER.get_size())
	var s := maxf(size.x / image.x, size.y / image.y)
	var offset := (size - image * s) / 2.0
	for b in [_start_button, _controls_button]:
		var rect: Rect2 = b.get_meta("cover_rect")
		b.position = offset + rect.position * s
		b.size = rect.size * s

func _quit_button() -> Button:
	var b := _button("", _ask_quit)
	b.name = "Quit"
	b.tooltip_text = "Quit"
	b.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	b.offset_left = -82
	b.offset_right = -28
	b.offset_top = -82
	b.offset_bottom = -28
	var skins := {"normal": UiTheme.button_skin(UiTheme.CREAM), "hover": UiTheme.button_skin(Color("fff0af"), true), "pressed": UiTheme.button_skin(Color("edc95d"), false, true)}
	for state in skins:
		skins[state].set_corner_radius_all(27)
		b.add_theme_stylebox_override(state, skins[state])
	var icon := Control.new()
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.draw.connect(func():
		var c := icon.size / 2.0 - Vector2(0, 2)
		icon.draw_arc(c, 11.0, deg_to_rad(-55), deg_to_rad(235), 24, UiTheme.INK, 3.5, true)
		icon.draw_line(c - Vector2(0, 15), c - Vector2(0, 3), UiTheme.INK, 3.5, true))
	b.add_child(icon)
	return b

func _build_quit_confirm() -> void:
	_quit_confirm = ColorRect.new()
	_quit_confirm.color = Color(0.12, 0.07, 0.21, 0.62)
	_quit_confirm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_quit_confirm)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_quit_confirm.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.card(UiTheme.CREAM, UiTheme.INK, 3, 22, 28))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	panel.add_child(box)
	var title := UiTheme.heading("Leave the salon?", 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	_quit_stay = _button("Stay", _close_quit_confirm)
	_quit_stay.custom_minimum_size = Vector2(150, 56)
	UiTheme.primary(_quit_stay)
	row.add_child(_quit_stay)
	var leave := _button("Quit", func(): get_tree().quit())
	leave.custom_minimum_size = Vector2(150, 56)
	row.add_child(leave)
	var pair: Array[Button] = [_quit_stay, leave]
	UiTheme.focus_loop(pair)
	_quit_confirm.hide()

func _ask_quit() -> void:
	if _quit_confirm == null or _controls.visible or _chapters.visible: return
	_quit_return = get_viewport().gui_get_focus_owner() as Button
	for b in _menu_buttons: b.focus_mode = Control.FOCUS_NONE
	_quit_confirm.show()
	UiTheme.focus_if_visible.call_deferred(_quit_stay)

func _close_quit_confirm() -> void:
	_quit_confirm.hide()
	for b in _menu_buttons: b.focus_mode = Control.FOCUS_ALL
	UiTheme.focus_if_visible.call_deferred(_quit_return if _quit_return in _menu_buttons else _start_button)

func _build_chapters() -> void:
	_map_view = SalonMap.new()
	_chapters = _map_view
	add_child(_chapters)
	_play_buttons = _map_view.buttons
	_chapter_back = _map_view.back
	_opening_button = _map_view.opening_button
	_map_play = _map_view.play_button
	_map_title = _map_view.stage_name
	_map_detail = _map_view.stage_detail
	_chapter_footer = _map_view.footer
	_chapter_shortcuts = _map_view.shortcuts
	_map_view.chapter_selected.connect(_select_chapter)
	_map_view.play_requested.connect(func(): play(_selected_chapter))
	_map_view.back_requested.connect(_close_chapters)
	_map_view.opening_requested.connect(_open_story)
	_map_view.rooms_requested.connect(_open_rooms)
	for i in _play_buttons.size():
		_play_buttons[i].focus_entered.connect(_select_chapter.bind(i))
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
		var deaths := Progress.best_deaths(index)
		_map_detail.text += "  |  Best %s  |  %d %s" % [Progress.format_time(Progress.best_time(index)), deaths, "death" if deaths == 1 else "deaths"]
	var names: Array[String] = []
	for i in Progress.LEVELS.size(): names.append(_chapter_name(i))
	_map_view.refresh(index, names)

func _latest_unlocked() -> int:
	for i in range(Progress.LEVELS.size() - 1, -1, -1):
		if Progress.is_unlocked(i): return i
	return 0

func _focus_latest() -> void:
	UiTheme.focus_if_visible.call_deferred(_play_buttons[_latest_unlocked()] if _chapters.visible else _start_button)

func _open_chapters(selected: int = -1) -> void:
	if _controls.visible: return
	for b in _menu_buttons: b.focus_mode = Control.FOCUS_NONE
	_chapters.show()
	_select_chapter(selected if Progress.is_unlocked(selected) else _latest_unlocked())
	var enabled: Array[Button] = []
	for b in _play_buttons:
		if not b.disabled: enabled.append(b)
	enabled.append_array([_map_play, _opening_button, _chapter_back])
	if _map_view.rooms_button.visible: enabled.append(_map_view.rooms_button)
	for b in enabled: b.focus_mode = Control.FOCUS_ALL
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
	UiTheme.focus_if_visible.call_deferred(_play_buttons[_selected_chapter])

func _close_chapters() -> void:
	_chapters.hide()
	for b in _menu_buttons: b.focus_mode = Control.FOCUS_ALL
	UiTheme.focus_if_visible.call_deferred(_chapters_button)

func _enter_game() -> void:
	if _controls.visible or _chapters.visible: return
	if Progress.has_seen_opening():
		_open_chapters()
		return
	Progress.mark_opening_seen()
	var opening := Opening.new()
	opening.return_to_chapters = true
	get_tree().root.add_child(opening)
	get_tree().current_scene = opening
	queue_free()

func play(index: int) -> void:
	if index >= 0 and index < Progress.LEVELS.size() and Progress.is_unlocked(index) and not _controls.visible:
		get_tree().change_scene_to_file(Progress.LEVELS[index].path)

## Story and postgame room collections share a modal with a contained focus loop.
func _open_collection(title: String, subtitle: String, kind: String) -> VBoxContainer:
	_collection_return = get_viewport().gui_get_focus_owner()
	_collection_kind = kind
	for b in _menu_buttons + _play_buttons + [_map_play, _opening_button, _chapter_back, _map_view.rooms_button]:
		b.focus_mode = Control.FOCUS_NONE
	_collection_buttons.clear()
	_collection = ColorRect.new()
	_collection.color = Color(0.12, 0.07, 0.21, 0.72)
	_collection.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_collection)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_collection.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 580
	panel.add_theme_stylebox_override("panel", UiTheme.card(UiTheme.CREAM, UiTheme.INK, 4, 26, 24))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var heading := UiTheme.heading(title, 38)
	box.add_child(heading)
	var detail := UiTheme.label(subtitle, 19)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size.x = 520
	box.add_child(detail)
	return box

func _collection_button(box: VBoxContainer, text: String, action: Callable, locked := false) -> void:
	var b := _button(text, action)
	b.custom_minimum_size.y = 52
	b.disabled = locked
	box.add_child(b)
	_collection_buttons.append(b)

func _finish_collection(box: VBoxContainer) -> void:
	_collection_button(box, "‹  Back", _close_collection)
	var enabled: Array[Button] = []
	for b in _collection_buttons:
		if not b.disabled: enabled.append(b)
	UiTheme.focus_loop(enabled)
	UiTheme.focus_if_visible.call_deferred(enabled[0])

func _open_story() -> void:
	if _controls.visible or is_instance_valid(_collection): return
	var box := _open_collection("Story", "Replay the story whenever you like.", "story")
	_collection_button(box, "Opening  ·  39 sec", _replay_story.bind(false))
	_collection_button(box, "Ending  ·  25 sec" if Progress.campaign_completed() else "Ending  ·  Complete all chapters to unlock", _replay_story.bind(true), not Progress.campaign_completed())
	_finish_collection(box)

func _replay_story(ending: bool) -> void:
	if ending and not Progress.campaign_completed(): return
	if ending: Progress.mark_ending_seen()
	# Keep the map, destination and records in place beneath the replay.
	var cg: Control = Ending.new() if ending else load("res://scenes/ui/storyboard_cutscene.gd").new()
	if not ending: cg.shots = Opening.SHOTS
	add_child(cg)
	_collection.hide()
	_collection.set_meta("cg", cg)
	cg.finished.connect(func():
		cg.queue_free()
		_collection.show()
		UiTheme.focus_if_visible.call_deferred(_collection_buttons[1 if ending else 0]))

func _open_rooms() -> void:
	if not Progress.campaign_completed() or _controls.visible or is_instance_valid(_collection): return
	var chapter: Node = load(Progress.LEVELS[_selected_chapter].path).instantiate()
	var box := _open_collection(Progress.LEVELS[_selected_chapter].title, "Choose a room. Replays keep chapter records unchanged.", "rooms")
	var i := 0
	for room in chapter.get_node("Rooms").get_children():
		_collection_button(box, room.title, _play_room.bind(_selected_chapter, i))
		i += 1
	chapter.free()
	_finish_collection(box)

func _play_room(chapter_index: int, room_index: int) -> void:
	if not Progress.campaign_completed() or chapter_index < 0 or chapter_index >= Progress.LEVELS.size(): return
	var level: Level = load(Progress.LEVELS[chapter_index].path).instantiate()
	if room_index < 0 or room_index >= level.get_node("Rooms").get_child_count():
		level.free()
		return
	level.start_room = room_index
	level.room_replay = true
	var tree := get_tree()
	tree.root.add_child(level)
	tree.current_scene = level
	queue_free()

func _close_collection() -> void:
	_collection.queue_free()
	_collection = null
	if _chapters.visible:
		var selected := _selected_chapter
		_open_chapters(selected)
	else:
		for b in _menu_buttons: b.focus_mode = Control.FOCUS_ALL
	UiTheme.focus_if_visible.call_deferred(_collection_return if is_instance_valid(_collection_return) else _start_button)

func _toggle_controls(tab: int = 3) -> void:
	if _controls.visible:
		_controls.dismiss()
		return
	_help_from_chapters = _chapters.visible
	for b in _menu_buttons + _play_buttons + [_opening_button, _chapter_back, _map_play, _map_view.rooms_button]: b.focus_mode = Control.FOCUS_NONE
	_controls.open(tab)

func _guide_closed() -> void:
	for b in _menu_buttons + _play_buttons + [_opening_button, _chapter_back, _map_play]: b.focus_mode = Control.FOCUS_ALL
	if _help_from_chapters:
		_open_chapters()
	else:
		UiTheme.focus_if_visible.call_deferred(_controls_button)

func _unhandled_input(event: InputEvent) -> void:
	if _controls.visible: return
	if is_instance_valid(_collection):
		if event.is_action_pressed("ui_cancel"):
			_close_collection()
			get_viewport().set_input_as_handled()
		return
	if _quit_confirm and _quit_confirm.visible:
		if event.is_action_pressed("ui_cancel"):
			_close_quit_confirm()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("show_help"):
		_toggle_controls(4)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("menu_opening"):
		get_viewport().set_input_as_handled()
		_open_story()
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
	if event.is_action_pressed("ui_cancel"):
		if _chapters.visible:
			_close_chapters()
		elif _quit_confirm:
			_ask_quit()
		else:
			return
		get_viewport().set_input_as_handled()

func _button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 44
	UiTheme.wire_button(b)
	b.pressed.connect(action)
	return b
