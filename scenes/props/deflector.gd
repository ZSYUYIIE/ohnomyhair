class_name Deflector
extends Area2D
## Reflector plate. Only parried scissors (player_attack) see it, so incoming enemy scissors
## pass straight through. While raised it turns a scissor straight up.

var raised := false


func _ready() -> void:
	collision_layer = Layers.INTERACTABLES
	collision_mask = 0
	Player._add_rect_shape(self, Vector2(12, 16), Vector2.ZERO)


func raise() -> void:
	raised = true
	queue_redraw()


func lower() -> void:
	raised = false
	queue_redraw()


func on_scissor(scissor: Scissor) -> void:
	if raised:
		scissor.redirect(Vector2.UP, Vector2(global_position.x, scissor.global_position.y))


func _draw() -> void:
	if raised:
		draw_line(Vector2(-7, 7), Vector2(7, -7), Color("5ce1e6"), 3.0)
	else:
		draw_line(Vector2(-7, 7), Vector2(7, 7), Color("5c6b7a"), 3.0)
	draw_circle(Vector2(0, 7), 2.0, Color("4a4a5a"))
