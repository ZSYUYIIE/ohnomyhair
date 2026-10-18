extends Node2D
## Gold wall ring for Long Straight Hair. Rings are targets, not solid platforms.
func _ready() -> void:
	add_to_group("hair_anchors")
	queue_redraw()
func _draw() -> void:
	draw_circle(Vector2.ZERO, 17, Color("2b2140"))
	draw_circle(Vector2.ZERO, 13, Color("f1c40f"))
	draw_circle(Vector2.ZERO, 7, Color("fff8ef"))
