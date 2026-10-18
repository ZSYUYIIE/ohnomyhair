@tool
class_name RoomExit
extends Area2D
## Door that fires `both_inside` once both players stand in it. Position is the top-left corner.

signal both_inside

## The glass shop door; the OPEN sign and the arrival pips above are drawn on top.
const ART := preload("res://assets/art/props/prop_exit.png")

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
	var door := door_rect()
	draw_texture_rect(ART, door, false)
	# Hanging OPEN sign.
	var cx := door.get_center().x
	var sign_rect := Rect2(Vector2(cx - 22.0, door.position.y + 10.0), Vector2(44, 16))
	draw_line(Vector2(cx - 14.0, door.position.y), sign_rect.position + Vector2(8, 0), frame, 1.0)
	draw_line(Vector2(cx + 14.0, door.position.y), sign_rect.position + Vector2(36, 0), frame, 1.0)
	draw_rect(sign_rect, Color("fffaf0"))
	draw_string(ThemeDB.fallback_font, sign_rect.position + Vector2(4, 13), "OPEN", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("c0392b"))
	for i in 2:
		var pip := Vector2(cx - 10.0 + i * 20.0, door.position.y - 12.0)
		draw_circle(pip, 6.0, frame if i < _inside else Color(frame, 0.25))


## Where the door picture goes: the biggest 2:3 door that fits the exit area, standing on
## its bottom edge in the middle, so an exit of any size never squashes or stretches it.
func door_rect() -> Rect2:
	var ratio := float(ART.get_width()) / ART.get_height()
	var h := minf(size.y, size.x / ratio)
	var w := h * ratio
	return Rect2(Vector2((size.x - w) / 2.0, size.y - h), Vector2(w, h))
