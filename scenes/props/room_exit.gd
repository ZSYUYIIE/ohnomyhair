@tool
class_name RoomExit
extends Area2D
## Door that fires `both_inside` once both players stand in it. Position is the top-left corner.

signal both_inside

@export var size := Vector2(64, 96):
	set(value):
		size = value
		queue_redraw()

var _inside := 0
var _fired := false


func _ready() -> void:
	queue_redraw()
	if Engine.is_editor_hint():
		return
	var rect := RectangleShape2D.new()
	rect.size = size
	$Shape.shape = rect
	$Shape.position = size / 2.0


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var count := 0
	for body in get_overlapping_bodies():
		if body.is_in_group("players"):
			count += 1
	if count != _inside:
		_inside = count
		queue_redraw()
	if count >= 2 and not _fired:
		_fired = true
		both_inside.emit()


func _draw() -> void:
	var frame := Color("2e8b57")
	draw_rect(Rect2(Vector2.ZERO, size), Color(frame, 0.12 + 0.2 * _inside))
	draw_rect(Rect2(Vector2.ZERO, size), frame, false, 4.0)
	# Hanging OPEN sign.
	var sign_rect := Rect2(Vector2(size.x / 2.0 - 22.0, 10.0), Vector2(44, 16))
	draw_line(Vector2(size.x / 2.0 - 14.0, 0), sign_rect.position + Vector2(8, 0), frame, 1.0)
	draw_line(Vector2(size.x / 2.0 + 14.0, 0), sign_rect.position + Vector2(36, 0), frame, 1.0)
	draw_rect(sign_rect, Color("fffaf0"))
	draw_string(ThemeDB.fallback_font, sign_rect.position + Vector2(4, 13), "OPEN", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("c0392b"))
	for i in 2:
		var pip := Vector2(size.x / 2.0 - 10.0 + i * 20.0, -12.0)
		draw_circle(pip, 6.0, frame if i < _inside else Color(frame, 0.25))
