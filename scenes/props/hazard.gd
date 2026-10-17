@tool
class_name Hazard
extends Area2D
## Kills any player overlapping it while active (dye pools, spikes).
## Position is the top-left corner.

@export var size := Vector2(128, 64):
	set(value):
		size = value
		queue_redraw()
@export var color := Color("8e44ad")


func _ready() -> void:
	queue_redraw()
	if Engine.is_editor_hint():
		return
	var rect := RectangleShape2D.new()
	rect.size = size
	$Shape.shape = rect
	$Shape.position = size / 2.0


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or not is_active():
		return
	for body in get_overlapping_bodies():
		if body.has_method("die"):
			body.die()


func is_active() -> bool:
	return true


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), color)
	draw_line(Vector2(0, 2), Vector2(size.x, 2), color.lightened(0.4), 4.0)
