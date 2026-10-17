class_name HitSwitch
extends Area2D
## Opens once when a parried scissor hits it, then stays on (latching).

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
	draw_rect(Rect2(-14, -14, 28, 28), Color("2c2c34"))
	draw_rect(Rect2(-10, -10, 20, 20), Color("2ecc71") if pressed else Color("e74c3c"))
