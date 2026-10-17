class_name Lever
extends Area2D
## Pulled by Twin Tails' skill. spring_time 0 = toggle; > 0 = springs back after that many seconds.
## Origin is at the base (floor level).

signal activated
signal deactivated

@export var spring_time := 0.0

var on := false
var _remaining := 0.0


func _ready() -> void:
	add_to_group("levers")
	collision_layer = Layers.INTERACTABLES
	collision_mask = 0
	Player._add_rect_shape(self, Vector2(10, 14), Vector2(0, -7))


func interact(_by: Node) -> void:
	if spring_time > 0.0:
		on = true
		_remaining = spring_time
		activated.emit()
	else:
		on = not on
		if on:
			activated.emit()
		else:
			deactivated.emit()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if spring_time > 0.0 and on:
		_remaining -= delta
		if _remaining <= 0.0:
			on = false
			deactivated.emit()
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-5, -4, 10, 4), Color("4a4a5a"))
	var tip := Vector2(7, -10) if on else Vector2(-7, -10)
	draw_line(Vector2(0, -3), tip, Color("bdc3c7"), 2.0)
	draw_circle(tip, 2.5, Color("e8508a"))
	if on and spring_time > 0.0:
		draw_rect(Rect2(-8, -18, 16.0 * _remaining / spring_time, 2), Color("f1c40f"))
