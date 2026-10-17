@tool
class_name Lever
extends Area2D
## Pulled by twin-tails (skill key while in reach). Connect a MovingBlock's
## `trigger` to this node; it listens to `toggled`.

signal toggled(on: bool)

@export var one_shot := true

var is_on := false


func _ready() -> void:
	queue_redraw()


func interact(_by: Node) -> void:
	if one_shot and is_on:
		return
	is_on = not is_on
	toggled.emit(is_on)
	queue_redraw()


func _draw() -> void:
	var tip := Vector2(12, -14) if is_on else Vector2(-12, -14)
	draw_rect(Rect2(-12, 8, 24, 8), Color("4a3b2a"))
	draw_line(Vector2(0, 10), tip, Color("d8d8d8"), 4.0)
	draw_circle(tip, 6.0, Color("7ee081") if is_on else Color("ff6b6b"))
