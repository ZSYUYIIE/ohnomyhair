@tool
class_name MovingBlock
extends AnimatableBody2D
## Solid block (bridge / lift / gate). Position is the top-left corner.
## When `trigger` (e.g. a Lever) emits toggled(true) it slides by `move_offset`.

@export var size := Vector2(64, 32):
	set(value):
		size = value
		queue_redraw()
@export var move_offset := Vector2.ZERO:
	set(value):
		move_offset = value
		queue_redraw()
@export var duration := 0.6
@export var color := Color("c9a227")
@export var trigger: Node

var _home := Vector2.ZERO
var _tween: Tween


func _ready() -> void:
	queue_redraw()
	if Engine.is_editor_hint():
		return
	var rect := RectangleShape2D.new()
	rect.size = size
	$Shape.shape = rect
	$Shape.position = size / 2.0
	_home = position
	if trigger:
		trigger.toggled.connect(_on_trigger_toggled)


func _on_trigger_toggled(on: bool) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position", _home + (move_offset if on else Vector2.ZERO), duration)


func _draw() -> void:
	var wood := Color("a0714f")
	draw_rect(Rect2(Vector2.ZERO, size), wood)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 5)), Color("d9dde3"))   # chrome top rail
	# Rolled towels along the front, in the block's accent colour.
	var x := 10.0
	while x < size.x - 6.0 and size.y >= 24.0:
		var c := Vector2(x, minf(size.y - 9.0, 18.0))
		draw_circle(c, 6.0, color.lightened(0.35))
		draw_circle(c, 2.0, color.darkened(0.2))
		x += 16.0
	draw_rect(Rect2(Vector2.ZERO, size), wood.darkened(0.4), false, 2.0)
	if Engine.is_editor_hint() and move_offset != Vector2.ZERO:
		draw_rect(Rect2(move_offset, size), Color(color, 0.35), false, 2.0)
