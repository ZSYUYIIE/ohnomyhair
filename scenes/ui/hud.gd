class_name Hud
extends CanvasLayer
## Dedicated footer below the complete room view. Side mattes mask neighbouring rooms
## during camera pans. Each player card follows their current haircut and skill keys.

const CARD_W := 330.0
const CARD_H := 68.0
const FOOTER_HEIGHT := 88.0
var _cards: HBoxContainer

var level: Level
var _names := {}
var _keys := {}
var _hearts := {}
var _portraits := {}
var _stage: Label
var _stats: Label


func _ready() -> void:
	layer = 10
	level = get_parent() as Level
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UiTheme.get_theme()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var room_height := 720.0 - FOOTER_HEIGHT
	var side_width := (1280.0 - 1280.0 * room_height / 720.0) / 2.0
	for rect in [Rect2(0, 0, side_width, room_height), Rect2(1280.0 - side_width, 0, side_width, room_height), Rect2(0, room_height, 1280, FOOTER_HEIGHT)]:
		var matte := ColorRect.new()
		matte.position = rect.position
		matte.size = rect.size
		matte.color = UiTheme.WOOD if rect.position.y >= room_height else Color("49344e")
		matte.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(matte)
	_cards = HBoxContainer.new()
	_cards.name = "HudCards"
	_cards.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_cards.offset_left = 8
	_cards.offset_right = -8
	_cards.offset_top = -CARD_H - 10
	_cards.offset_bottom = -10
	_cards.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_cards.add_theme_constant_override("separation", 12)
	root.add_child(_cards)
	_cards.add_child(_player_card(1))
	_cards.add_child(_stage_card())
	_cards.add_child(_player_card(2))


func _process(_delta: float) -> void:
	for p: Player in get_tree().get_nodes_in_group("players"):
		var id := p.player_id
		if not _names.has(id):
			continue
		_names[id].text = "P%d  %s" % [id, p.ability.display_name]
		var skill := "G" if id == 1 else "K"
		var attack := "F" if id == 1 else "L"
		_keys[id].text = "%s %s  /  %s %s" % [skill, Player.HAIR_INFO[p.hair].skill, attack, Player.HAIR_INFO[p.hair].attack]
		if p.is_wet():
			_keys[id].text = "SOAKED  /  Find warm air to dry off"
		_hearts[id].set_values(maxi(p.hp, 0) if p.alive else 0, p.max_hp)
		_portraits[id].set_colors(p.ability.body_color, p.ability.get("HAIR_COLOR"))
		_portraits[id].set_frames(p.ability.frames)
	if level:
		var room := level.rooms[level.room_index] if level.rooms.size() > 0 else null
		var room_name: String = room.title.get_slice(" - ", 1) if room and " - " in room.title else (room.title if room else "")
		_stage.text = "ROOM %d/%d  /  %s" % [level.room_index + 1, level.rooms.size(), room_name]
		_stats.text = "%s  /  %d deaths  /  Esc pause · R retry · F1 help" % [Progress.format_time(level.level_time), level.deaths]


func _player_card(id: int) -> Control:
	var panel := _plate()
	var left := id == 1
	panel.add_theme_stylebox_override("panel", UiTheme.card(Color("ffe6ef") if left else Color("e1f2fc"), UiTheme.INK, 3, 18, 6))
	panel.custom_minimum_size = Vector2(CARD_W, CARD_H)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var portrait := Portrait.new()
	_portraits[id] = portrait
	row.add_child(portrait)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	var top := HBoxContainer.new()
	col.add_child(top)
	_names[id] = UiTheme.heading("P%d" % id, 19)
	_names[id].clip_text = true
	_names[id].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_names[id])
	_hearts[id] = HeartBar.new()
	top.add_child(_hearts[id])
	_keys[id] = UiTheme.label("", 16, UiTheme.MUTED)
	_keys[id].clip_text = true
	col.add_child(_keys[id])
	return panel


func _stage_card() -> Control:
	var panel := _plate()
	panel.custom_minimum_size.y = CARD_H
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	panel.add_child(col)
	_stage = UiTheme.heading("", 21)
	_stage.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stage.clip_text = true
	col.add_child(_stage)
	_stats = UiTheme.label("", 17, UiTheme.MUTED)
	_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats.clip_text = true
	col.add_child(_stats)
	return panel


func _plate() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.card(UiTheme.CREAM, UiTheme.INK, 3, 18, 6))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


## Little head-and-hair icon in the player's current colours.
class Portrait extends Control:
	const TWIN_FRAMES = preload("res://assets/art/characters/twin_tails/frames.tres")
	var body := Color.WHITE
	var hair := Color.WHITE
	var _frames: SpriteFrames = TWIN_FRAMES

	func set_frames(value: SpriteFrames) -> void:
		if value and value != _frames:
			_frames = value
			queue_redraw()

	func _init() -> void:
		custom_minimum_size = Vector2(34, 42)

	func set_colors(b: Color, h: Color) -> void:
		if b != body or h != hair:
			body = b
			hair = h
			queue_redraw()

	func _draw() -> void:
		draw_texture_rect(_frames.get_frame_texture("idle", 0), Rect2(-27, -28, 88, 83), false)


## Row of hearts: filled = HP left.
class HeartBar extends Control:
	var value := 3
	var max_value := 3

	func _init() -> void:
		custom_minimum_size = Vector2(3 * 22, 20)

	func set_values(v: int, m: int) -> void:
		if v != value or m != max_value:
			value = v
			max_value = m
			custom_minimum_size = Vector2(m * 22, 20)
			queue_redraw()

	func _draw() -> void:
		for i in max_value:
			var x := i * 22.0
			var c := Color("e74c3c") if i < value else Color(0.4, 0.3, 0.3, 0.3)
			draw_circle(Vector2(x + 6, 7), 5.0, c)
			draw_circle(Vector2(x + 14, 7), 5.0, c)
			draw_colored_polygon(PackedVector2Array([Vector2(x + 1.2, 9), Vector2(x + 18.8, 9), Vector2(x + 10, 19)]), c)
