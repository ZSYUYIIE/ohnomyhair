class_name Deflector
extends Area2D
## Reflector plate. Only parried scissors (player_attack) see it, so incoming enemy scissors
## pass straight through. While raised it turns a scissor straight up.
## Polls overlaps every frame instead of waiting for area_entered: a scissor parried right next
## to the plate is already overlapping it, and the plate can be raised after the scissor got here.

var raised := false


func _ready() -> void:
	collision_layer = Layers.INTERACTABLES
	collision_mask = Layers.PLAYER_ATTACK
	Player._add_rect_shape(self, Vector2(12, 16), Vector2.ZERO)


func raise() -> void:
	raised = true
	queue_redraw()


func lower() -> void:
	raised = false
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if not raised:
		return
	for area in get_overlapping_areas():
		if area is Scissor and area.deflected and area.direction.y == 0.0:
			area.redirect(Vector2.UP, Vector2(global_position.x, area.global_position.y))


func _draw() -> void:
	if raised:
		draw_line(Vector2(-7, 7), Vector2(7, -7), Color("5ce1e6"), 3.0)
	else:
		draw_line(Vector2(-7, 7), Vector2(7, 7), Color("5c6b7a"), 3.0)
	draw_circle(Vector2(0, 7), 2.0, Color("4a4a5a"))
