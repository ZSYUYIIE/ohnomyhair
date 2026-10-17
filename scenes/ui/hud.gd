class_name Hud
extends CanvasLayer
## Bottom bar, Fireboy & Watergirl style: one card per friend (portrait in their current
## hair colours, haircut name, hearts, keys) at the sides, and the stage card in the middle
## (level, room n/N and its name, time, deaths). It sits over the floor tiles because the
## ceilings hold gameplay (service bells, hints).

const CARD_W := 330.0
const CARD_H := 56.0

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
	for id in [1, 2]:
		root.add_child(_player_card(id))
	root.add_child(_stage_card())


func _process(_delta: float) -> void:
	for p: Player in get_tree().get_nodes_in_group("players"):
		var id := p.player_id
		if not _names.has(id):
			continue
		_names[id].text = "P%d  %s" % [id, p.ability.display_name]
		_keys[id].text = ("G skill   F attack" if id == 1 else "K skill   L attack")
		_hearts[id].set_values(maxi(p.hp, 0) if p.alive else 0, p.max_hp)
		_portraits[id].set_colors(p.ability.body_color, p.ability.get("HAIR_COLOR"))
	if level:
		var room := level.rooms[level.room_index] if level.rooms.size() > 0 else null
		var room_name: String = room.title.get_slice(" - ", 1) if room and " - " in room.title else (room.title if room else "")
		_stage.text = "%s   |   Room %d/%d  %s" % [level.level_title, level.room_index + 1, level.rooms.size(), room_name]
		_stats.text = "TIME %s      DEATHS %d      Esc pause   R restart" % [Progress.format_time(level.level_time), level.deaths]


func _player_card(id: int) -> Control:
	var panel := _plate()
	var left := id == 1
	panel.anchor_left = 0.0 if left else 1.0
	panel.anchor_right = panel.anchor_left
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 8.0 if left else -CARD_W - 8.0
	panel.offset_right = panel.offset_left + CARD_W
	panel.offset_top = -CARD_H - 6.0
	panel.offset_bottom = -6.0
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
	_names[id] = UiTheme.label("P%d" % id, 18)
	_names[id].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_names[id])
	_hearts[id] = HeartBar.new()
	top.add_child(_hearts[id])
	_keys[id] = UiTheme.label("", 14, Color(UiTheme.INK, 0.7))
	col.add_child(_keys[id])
	return panel


func _stage_card() -> Control:
	var panel := _plate()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -290.0
	panel.offset_right = 290.0
	panel.offset_top = -CARD_H - 6.0
	panel.offset_bottom = -6.0
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	panel.add_child(col)
	_stage = UiTheme.label("", 17)
	_stage.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stage.clip_text = true
	col.add_child(_stage)
	_stats = UiTheme.label("", 14, Color(UiTheme.INK, 0.75))
	_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_stats)
	return panel


func _plate() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.card(Color(UiTheme.CREAM, 0.93), UiTheme.WALNUT, 2, 10, 6))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


## Little head-and-hair icon in the player's current colours.
class Portrait extends Control:
	var body := Color.WHITE
	var hair := Color.WHITE

	func _init() -> void:
		custom_minimum_size = Vector2(34, 42)

	func set_colors(b: Color, h: Color) -> void:
		if b != body or h != hair:
			body = b
			hair = h
			queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(6, 12, 22, 28), body)
		draw_rect(Rect2(6, 6, 22, 8), hair)
		draw_rect(Rect2(2, 10, 5, 14), hair)
		draw_rect(Rect2(27, 10, 5, 14), hair)
		draw_rect(Rect2(19, 20, 3, 4), UiTheme.INK)


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
