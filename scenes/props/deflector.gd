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
	Player.add_rect_shape(self, Vector2(24, 32), Vector2.ZERO)


func set_raised(on: bool) -> void:
	raised = on
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if not raised:
		return
	for area in get_overlapping_areas():
		if area is Scissor and area.deflected and area.direction.y == 0.0:
			area.redirect(Vector2.UP, Vector2(global_position.x, area.global_position.y))


func _draw() -> void:
	if raised:
		draw_line(Vector2(-14, 14), Vector2(14, -14), Color("5ce1e6"), 6.0)
	else:
		draw_line(Vector2(-14, 14), Vector2(14, 14), Color("5c6b7a"), 6.0)
	draw_circle(Vector2(0, 14), 4.0, Color("4a4a5a"))
