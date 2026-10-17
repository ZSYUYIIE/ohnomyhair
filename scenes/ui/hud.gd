class_name Hud
extends CanvasLayer
## HP for both players, controls reminder, and the win banner.

var _status: Label
var _banner: Label


func _ready() -> void:
	layer = 10
	_status = _make_label(Vector2(4, 340), 8)
	_banner = _make_label(Vector2(0, 150), 16)
	_banner.size = Vector2(640, 40)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.text = "LEVEL CLEAR!\nPress R to play again"
	_banner.hide()
	Game.won.connect(_banner.show)


func _process(_delta: float) -> void:
	var parts: Array[String] = []
	for p in get_tree().get_nodes_in_group("players"):
		parts.append("P%d %s HP %d" % [p.player_id, "Twin Tails" if p.ability is TwinTails else "Pompadour", p.hp])
	parts.sort()
	_status.text = "   |   ".join(parts) + "   |   R restart"


func _make_label(at: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	add_child(label)
	return label
