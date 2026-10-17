@tool
class_name Lever
extends Area2D
## Pulled by twin-tails (skill key while in reach). Listeners connect to `toggled`
## (MovingBlock.trigger does this; Deflector uses set_raised).
## one_shot: stays down once pulled. spring_time > 0: springs back after that many
## seconds, and every pull re-arms the timer. Neither: a plain on/off toggle.

signal toggled(on: bool)

@export var one_shot := true
@export var spring_time := 0.0

var is_on := false
var _remaining := 0.0


func _ready() -> void:
	queue_redraw()


func interact(_by: Node) -> void:
	if spring_time > 0.0:
		_remaining = spring_time
		if not is_on:
			is_on = true
			toggled.emit(true)
	elif one_shot and is_on:
		return
	else:
		is_on = not is_on
		toggled.emit(is_on)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or spring_time <= 0.0 or not is_on:
		return
	_remaining -= delta
	if _remaining <= 0.0:
		is_on = false
		toggled.emit(false)
	queue_redraw()


func _draw() -> void:
	var tip := Vector2(12, -14) if is_on else Vector2(-12, -14)
	draw_rect(Rect2(-12, 8, 24, 8), Color("4a3b2a"))
	draw_line(Vector2(0, 10), tip, Color("d8d8d8"), 4.0)
	draw_circle(tip, 6.0, Color("7ee081") if is_on else Color("ff6b6b"))
	if spring_time > 0.0 and is_on:
		draw_rect(Rect2(-16, -30, 32.0 * _remaining / spring_time, 4), Color("f1c40f"))
