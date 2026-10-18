@tool
class_name Lever
extends Area2D
## Pulled by twin-tails (skill key while in reach). Listeners connect to `toggled`
## (MovingBlock.trigger does this).
## one_shot: stays down once pulled. spring_time > 0: springs back after that many
## seconds, and every pull re-arms the timer. Neither: a plain on/off toggle.

signal toggled(on: bool)

const ART := preload("res://assets/art/props/prop_lever.png")

@export var one_shot := true
@export var spring_time := 0.0

var is_on := false
var _remaining := 0.0


func _ready() -> void:
	queue_redraw()
	if not Engine.is_editor_hint(): add_to_group("levers")


func interact(_by: Node) -> void:
	Sound.play("lever")
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
	# The barber chair's hydraulic pump handle: frame 0 off, frame 1 on. Its base sits
	# on the floor at the bottom of the tile the lever is centred in.
	draw_texture_rect_region(ART, Rect2(-24, -32, 48, 48), Rect2(48 if is_on else 0, 0, 48, 48))
	if spring_time > 0.0 and is_on:
		draw_rect(Rect2(-16, -30, 32.0 * _remaining / spring_time, 4), Color("f1c40f"))
