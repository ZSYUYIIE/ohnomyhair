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


const ART := preload("res://assets/art/props/prop_bell.png")


func _draw() -> void:
	# Frames: waiting (chrome dome) | rung (gold).
	draw_texture_rect_region(ART, Rect2(-16, -16, 32, 36), Rect2(32 if pressed else 0, 0, 32, 36))
	if pressed:
		draw_string(ThemeDB.fallback_font, Vector2(-22, 36), "DING!", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("b8860b"))
