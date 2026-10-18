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
## Reinforced salon gel needs the Afro + Pompadour cannonball combo.
@export var requires_cannonball := false

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


func smash(powered := false) -> void:
	if _broken or (requires_cannonball and not powered):
		return
	_broken = true
	Sound.play("gel_smash")
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
	Sound.play("gel_regrow", 0.05, -4.0)
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
	PropArt.gloss(self, Rect2(Vector2.ZERO, size), Color("68d8c3"), 13)
	draw_line(Vector2(8, 17), Vector2(8, size.y - 15), Color("cefff1"), 3, true)
	for i in range(19, int(size.y) - 10, 27):
		draw_circle(Vector2(size.x * 0.65, i), 3.2, Color("cafff0"))
	if requires_cannonball:
		for y in range(12, int(size.y) - 8, 36):
			draw_line(Vector2(6, y), Vector2(size.x - 6, y), Color("ee9a42"), 7)
	if regrow_time > 0.0:
		# Drips along the bottom edge: this gel grows back.
		var x := 10.0
		while x < size.x - 8.0:
			draw_circle(Vector2(x, size.y + 1.0), 4.0, Color("2b2140"))
			draw_circle(Vector2(x, size.y), 2.6, gel)
			x += 18.0
