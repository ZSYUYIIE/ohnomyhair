class_name MainMenu
extends Control
## Salon title screen with the two friends beside a chapter grid.

const Guide := preload("res://scenes/ui/controls_guide.gd")
const DESCRIPTIONS := ["Glide, carry & sling your friend", "Parry scissors & ring the bells", "Ride warm air. Watch the shampoo!", "Swap haircuts & face the barber"]

var _cards: Array[PanelContainer] = []
var _play_buttons: Array[Button] = []
var _menu_buttons: Array[Button] = []
var _controls: Control
var _controls_button: Button


func _ready() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.get_theme()
	_build_backdrop()
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + edge, 48)
	for edge in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 28)
	add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	margin.add_child(col)
	col.add_child(UiTheme.label("A TWO-PLAYER SALON ESCAPE  /  SHARED KEYBOARD", 16, UiTheme.MUTED))
	col.add_child(UiTheme.label("OH NO MY HAIR!", 64))
	col.add_child(UiTheme.label("Two terrible haircuts. One great escape. Better together.", 22, UiTheme.MUTED))
	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 24)
	col.add_child(content)
	content.add_child(_friends_panel())
	var levels := VBoxContainer.new()
	levels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	levels.add_theme_constant_override("separation", 10)
	content.add_child(levels)
	levels.add_child(UiTheme.label("CHOOSE YOUR CHAPTER", 17, UiTheme.MUTED))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	levels.add_child(grid)
	for i in Progress.LEVELS.size():
		grid.add_child(_level_card(i))
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 14)
	col.add_child(buttons)
	_controls_button = _button("How to play & combos", _toggle_controls)
	buttons.add_child(_controls_button)
	_menu_buttons.append(_controls_button)
	var lab := _button("Style Lab", _play_lab)
	buttons.add_child(lab)
	_menu_buttons.append(lab)
	var quit_button := _button("Quit", func(): get_tree().quit())
	buttons.add_child(quit_button)
	_menu_buttons.append(quit_button)
	var tip := UiTheme.label("Arrow keys / Tab to choose     Enter to play", 17, UiTheme.MUTED)
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(tip)
	_controls = Guide.new()
	add_child(_controls)
	_controls.closed.connect(_guide_closed)
	_controls.hide()
	_wire_focus()
	_focus_latest()


func _wire_focus() -> void:
	var enabled: Array[Button] = []
	for button in _play_buttons:
		if not button.disabled:
			enabled.append(button)
	enabled.append_array(_menu_buttons)
	UiTheme.focus_loop(enabled)
	for i in _play_buttons.size():
		var b := _play_buttons[i]
		if b.disabled:
			continue
		for entry in [["left", i - 1 if i % 2 == 1 else -1], ["right", i + 1 if i % 2 == 0 else -1], ["top", i - 2], ["bottom", i + 2]]:
			var target: int = entry[1]
			if target >= 0 and target < _play_buttons.size() and not _play_buttons[target].disabled:
				b.set("focus_neighbor_" + entry[0], _play_buttons[target].get_path())


func _focus_latest() -> void:
	for i in range(_play_buttons.size() - 1, -1, -1):
		if not _play_buttons[i].disabled:
			UiTheme.focus_if_visible.call_deferred(_play_buttons[i])
			return


func play(index: int) -> void:
	if index >= 0 and index < Progress.LEVELS.size() and Progress.is_unlocked(index) and not _controls.visible:
		get_tree().change_scene_to_file(Progress.LEVELS[index].path)


func _play_lab() -> void:
	if not _controls.visible:
		get_tree().change_scene_to_file("res://scenes/levels/style_lab.tscn")


func _level_card(i: int) -> PanelContainer:
	var unlocked := Progress.is_unlocked(i)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(350, 0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", UiTheme.card(UiTheme.CREAM if unlocked else Color("eee6e1"), UiTheme.WALNUT if unlocked else Color("c5b9c5"), 2, 14, 16))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	card.add_child(box)
	box.add_child(UiTheme.label("CHAPTER 0%d  /  %s" % [i + 1, ("CLEARED" if Progress.is_cleared(i) else "READY") if unlocked else "LOCKED"], 14, UiTheme.MUTED))
	box.add_child(UiTheme.label(Progress.LEVELS[i].title, 27, UiTheme.INK if unlocked else UiTheme.MUTED))
	var info := "Finish chapter 1 to unlock" if i == 1 else "Finish chapters 1–%d to unlock" % i
	if unlocked:
		info = "Best %s  /  %d deaths" % [Progress.format_time(Progress.best_time(i)), Progress.best_deaths(i)] if Progress.is_cleared(i) else DESCRIPTIONS[i]
	var detail := UiTheme.label(info, 16, UiTheme.MUTED)
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(detail)
	var button := _button(("Play again" if Progress.is_cleared(i) else "Play together") if unlocked else "Locked", play.bind(i))
	button.disabled = not unlocked
	if unlocked:
		button.add_theme_stylebox_override("normal", UiTheme.card(Color("f9e39b"), UiTheme.WALNUT, 2, 9, 10))
	box.add_child(button)
	_cards.append(card)
	_play_buttons.append(button)
	return card


func _friends_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 390
	panel.add_theme_stylebox_override("panel", UiTheme.card(Color("f4eaf1"), Color("c5b4c8"), 2, 16, 20))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	box.add_child(UiTheme.label("MEET YOUR OTHER HALF", 17, UiTheme.MUTED))
	var portraits := HBoxContainer.new()
	portraits.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(portraits)
	for id in [1, 2]:
		var player_col := VBoxContainer.new()
		player_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		portraits.add_child(player_col)
		var art := TextureRect.new()
		var frames: SpriteFrames = load("res://assets/art/characters/%s/frames.tres" % ("twin_tails" if id == 1 else "pompadour"))
		var portrait := AtlasTexture.new()
		portrait.atlas = frames.get_frame_texture("idle", 0)
		portrait.region = Rect2(24, 32, 88, 78)
		art.texture = portrait
		art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.custom_minimum_size = Vector2(160, 130)
		art.size_flags_vertical = Control.SIZE_EXPAND_FILL
		player_col.add_child(art)
		var name_label := UiTheme.label("P1  Twin-Tails" if id == 1 else "P2  Pompadour", 19)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		player_col.add_child(name_label)
		var keys := UiTheme.label("A D move / W jump\nG skill / F whip" if id == 1 else "← → move / ↑ jump\nK skill / L parry", 16, UiTheme.MUTED)
		keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		player_col.add_child(keys)
	var note := UiTheme.label("Bring a friend. You will need each other.\nHair is health. Both players must reach the exit.", 17)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(note)
	return panel


func _toggle_controls() -> void:
	if _controls.visible:
		_controls.dismiss()
		return
	for b in _play_buttons + _menu_buttons:
		b.focus_mode = Control.FOCUS_NONE
	_controls.open()


func _guide_closed() -> void:
	for b in _play_buttons + _menu_buttons:
		b.focus_mode = Control.FOCUS_ALL
	UiTheme.focus_if_visible.call_deferred(_controls_button)


func _button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 46)
	b.pressed.connect(on_press)
	return b


func _build_backdrop() -> void:
	var wall := ColorRect.new()
	wall.set_anchors_preset(Control.PRESET_FULL_RECT)
	wall.color = Color("f6e7ec")
	wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wall)
	var decor := SalonDecor.new()
	decor.wall_color = wall.color
	decor.modulate.a = 0.3
	decor.layout_seed = 7
	add_child(decor)
