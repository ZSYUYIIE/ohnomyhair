class_name HitSwitch
extends Area2D
## Reception service bell: rings once when a parried scissor hits it, then stays on (latching).

signal activated

var pressed := false


func _ready() -> void:
	collision_layer = Layers.INTERACTABLES
	collision_mask = 0
	Player.add_rect_shape(self, Vector2(28, 28), Vector2.ZERO)


func on_scissor(scissor: Scissor) -> void:
	scissor.queue_free()
	if pressed:
		return
	pressed = true
	activated.emit()
	queue_redraw()


func _draw() -> void:
	# Bracket from the ceiling, wooden base plate, then the dome.
	draw_rect(Rect2(-3, -14, 6, 8), Color("6b6f78"))
	draw_rect(Rect2(-14, -6, 28, 5), Color("6b4a35"))
	var dome := Color("ffd23f") if pressed else Color("d9dde3")
	draw_circle(Vector2(0, 6), 12.0, dome)
	draw_rect(Rect2(-14, 10, 28, 4), dome.darkened(0.3))
	draw_circle(Vector2(0, -2), 3.0, dome.darkened(0.2))
	draw_line(Vector2(-6, 1), Vector2(-2, -2), Color(1, 1, 1, 0.8), 2.0)
	if pressed:
		draw_string(ThemeDB.fallback_font, Vector2(-22, 34), "DING!", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("b8860b"))
