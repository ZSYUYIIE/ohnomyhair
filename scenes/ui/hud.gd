class_name Hud
extends CanvasLayer
## Bottom bar: each player's haircut and HP, plus the controls reminder.

var _status: Label


func _ready() -> void:
	layer = 10
	_status = Label.new()
	_status.anchor_top = 1.0
	_status.anchor_bottom = 1.0
	_status.offset_left = 12.0
	_status.offset_top = -32.0
	_status.add_theme_font_size_override("font_size", 16)
	_status.add_theme_color_override("font_outline_color", Color.BLACK)
	_status.add_theme_constant_override("outline_size", 6)
	add_child(_status)


func _process(_delta: float) -> void:
	var parts: Array[String] = []
	for p: Player in get_tree().get_nodes_in_group("players"):
		var keys := "G skill  F attack" if p.player_id == 1 else "K skill  L attack"
		parts.append("P%d %s  HP %d   (%s)" % [p.player_id, p.ability.display_name, maxi(p.hp, 0), keys])
	parts.sort()
	_status.text = "      ".join(parts) + "      R restart room"
