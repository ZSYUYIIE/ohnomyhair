@tool
class_name BreakableWall
extends StaticBody2D
## Hair-gel wall. Position is the top-left corner. A pompadour dash calls smash().

@export var size := Vector2(64, 160):
	set(value):
		size = value
		queue_redraw()

var _broken := false


func _ready() -> void:
	queue_redraw()
	if Engine.is_editor_hint():
		return
	var rect := RectangleShape2D.new()
	rect.size = size
	$Shape.shape = rect
	$Shape.position = size / 2.0


func smash() -> void:
	if _broken:
		return
	_broken = true
	$Shape.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)


func _draw() -> void:
	var gel := Color("9be7d8")
	draw_rect(Rect2(Vector2.ZERO, size), gel)
	var y := 8.0
	while y < size.y:
		draw_line(Vector2(4, y), Vector2(size.x - 4, y + 10), gel.darkened(0.25), 2.0)
		y += 24.0
	draw_rect(Rect2(Vector2.ZERO, size), gel.darkened(0.45), false, 2.0)
