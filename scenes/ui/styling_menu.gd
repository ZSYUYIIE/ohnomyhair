extends CanvasLayer
## Modal co-op selection; choices are staged until both players confirm together.
signal styles_chosen(styles: Array[int])
signal closed
const FRAME_DIRS := ["twin_tails", "pompadour"]
var selections: Array[int] = [0, 1]
## Haircuts this room's chair offers (Room.styles); the rest are greyed out.
var allowed := PackedInt32Array([0, 1])
var _options: Array[Button] = []
var _descriptions: Array[Label] = []
var _portraits: Array[TextureRect] = []
var _confirm: Button

func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UiTheme.get_theme()
	add_child(root)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.12, 0.08, 0.18, 0.8)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1120, 570)
	panel.add_theme_stylebox_override("panel", UiTheme.card(UiTheme.CREAM, UiTheme.INK, 4, 26, 18))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	box.add_child(UiTheme.heading("Two friends. Pick your roles.", 38))
	box.add_child(UiTheme.label("Your keys stay the same. Your haircut changes the skill. Save to heal both friends.", 20, UiTheme.MUTED))
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 20)
	box.add_child(row)
	for id in 2:
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(card)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 10)
		card.add_child(col)
		col.add_child(UiTheme.label("P%d  /  %s" % [id + 1, "G skill · F attack" if id == 0 else "K skill · L attack"], 24))
		var preview := TextureRect.new()
		preview.custom_minimum_size = Vector2(0, 90)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		col.add_child(preview)
		_portraits.append(preview)
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)
		col.add_child(grid)
		for hair in Player.HAIR_INFO.size():
			var option := Button.new()
			option.custom_minimum_size = Vector2(240, 46)
			option.pressed.connect(choose.bind(id, hair))
			grid.add_child(option)
			_options.append(option)
		var detail := UiTheme.label("", 18, UiTheme.MUTED)
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.custom_minimum_size.y = 72
		col.add_child(detail)
		_descriptions.append(detail)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 14)
	box.add_child(buttons)
	_confirm = Button.new()
	_confirm.text = "Save styles & room checkpoint"
	_confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirm.custom_minimum_size.y = 48
	_confirm.pressed.connect(commit)
	buttons.add_child(_confirm)
	var cancel := Button.new()
	cancel.text = "Cancel / Esc"
	cancel.pressed.connect(dismiss)
	buttons.add_child(cancel)
	var focus: Array[Button] = []
	focus.append_array(_options)
	focus.append_array([_confirm, cancel])
	UiTheme.focus_loop(focus)
	hide()

func open(players: Array[Player], styles := PackedInt32Array([0, 1])) -> void:
	allowed = styles
	for i in 2: selections[i] = players[i].hair
	_update()
	show()
	UiTheme.focus_if_visible.call_deferred(_options[selections[0]])

func choose(player_index: int, hair: int) -> void:
	if player_index < 0 or player_index > 1 or hair < 0 or hair >= Player.HAIR_INFO.size(): return
	if hair not in allowed: return
	selections[player_index] = hair
	_update()

func _update() -> void:
	for id in 2:
		var style := selections[id]
		var info: Dictionary = Player.HAIR_INFO[style]
		_descriptions[id].text = info.about
		# Full-resolution portrait (tools/art/make_portraits.py), sharp at menu size.
		_portraits[id].texture = load("res://assets/art/characters/portraits/%s.png" % FRAME_DIRS[style])
		for h in Player.HAIR_INFO.size():
			var option := _options[id * Player.HAIR_INFO.size() + h]
			option.text = ("✓ " if h == style else "") + Player.HAIR_INFO[h].name
			option.disabled = h not in allowed
			option.visible = h in allowed
			option.add_theme_stylebox_override("normal", UiTheme.card(Color("f9e39b") if h == style else UiTheme.CREAM, UiTheme.WALNUT, 2, 8, 8))
	var same := selections[0] == selections[1]
	_confirm.disabled = same
	_confirm.text = "Pick two different haircuts" if same else "Save styles & room checkpoint"

func commit() -> void:
	if selections[0] == selections[1]:
		return
	hide()
	styles_chosen.emit(selections.duplicate())

func dismiss() -> void:
	hide()
	closed.emit()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		dismiss()
		get_viewport().set_input_as_handled()
