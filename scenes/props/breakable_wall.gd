@tool
class_name BreakableWall
extends StaticBody2D
## Hair-gel wall. Position is the top-left corner. A pompadour dash calls smash().
## regrow_time > 0: the gel oozes back after that many seconds (once nobody is inside),
## so one friend can't smash it and leave it open for the other.

@export var size := Vector2(64, 160):
	set(value):
		size = value
		queue_redraw()

@export var regrow_time := 0.0

var _broken := false
var _regrow_left := 0.0


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
	if regrow_time > 0.0:
		_regrow_left = regrow_time
		tween.tween_property(self, "modulate:a", 0.15, 0.2)
	else:
		tween.tween_property(self, "modulate:a", 0.0, 0.25)
		tween.tween_callback(queue_free)


func is_solid() -> bool:
	return not _broken


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or not _broken or regrow_time <= 0.0:
		return
	_regrow_left -= delta
	if _regrow_left > 0.0 or _player_inside():
		return
	_broken = false
	$Shape.set_deferred("disabled", false)
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)


func _player_inside() -> bool:
	var me := Rect2(global_position, size)
	for p: Player in get_tree().get_nodes_in_group("players"):
		if me.intersects(Rect2(p.global_position - Player.HALF_SIZE, Player.HALF_SIZE * 2.0)):
			return true
	return false


func _draw() -> void:
	var gel := Color("9be7d8")
	draw_rect(Rect2(Vector2.ZERO, size), gel)
	var y := 8.0
	while y < size.y:
		draw_line(Vector2(4, y), Vector2(size.x - 4, y + 10), gel.darkened(0.25), 2.0)
		y += 24.0
	draw_rect(Rect2(Vector2.ZERO, size), gel.darkened(0.45), false, 2.0)
	if regrow_time > 0.0:
		# Drips along the bottom edge: this gel grows back.
		var x := 6.0
		while x < size.x - 4.0:
			draw_rect(Rect2(x, size.y, 4, 8), gel.darkened(0.15))
			x += 16.0
