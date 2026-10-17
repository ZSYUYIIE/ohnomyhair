class_name HairDryer
extends Area2D
## Floor-standing salon blow dryer: a column of warm air above it. Position is the
## column's top-left corner; the dryer sits at its bottom center.
## - A gliding twin-tails rises (to the top of the column, then bobs there).
##   Carrying a friend she can only hover: too heavy to climb.
## - Anyone else falls slower in the warm air.
## - Everyone inside is dried instantly (shampoo showers make you wet).
## Combo "Hair-copter": pompadour stands on the gliding twin-tails' head and rides up.

@export var size := Vector2(64, 320)
@export var lift_speed := 300.0
@export var lift_accel := 1800.0
@export var warm_fall_speed := 260.0

var _t := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.PLAYERS
	monitorable = false
	Player.add_rect_shape(self, size, size / 2.0)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	_t += delta
	for body in get_overlapping_bodies():
		if body is Player:
			body.dry()
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if body is Player and self not in body.updrafts:
		body.updrafts.append(self)


func _on_body_exited(body: Node) -> void:
	if body is Player:
		body.updrafts.erase(self)


func _exit_tree() -> void:
	for p: Player in get_tree().get_nodes_in_group("players"):
		p.updrafts.erase(self)


func _draw() -> void:
	# Warm air: faint streaks rising up the column.
	var streaks := int(size.x / 16.0)
	for i in streaks:
		var x := 8.0 + i * 16.0
		var y := size.y - fmod(_t * 220.0 + i * 57.0, size.y)
		draw_line(Vector2(x, y), Vector2(x + sin(_t * 6.0 + i) * 3.0, y - 26.0), Color(1, 0.95, 0.85, 0.45), 3.0)
	draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.85, 0.6, 0.08))
	# The dryer: chrome stand and a pink nozzle pointing up.
	var base := Vector2(size.x / 2.0, size.y)
	draw_rect(Rect2(base + Vector2(-18, -6), Vector2(36, 6)), Color("9aa0a6"))
	draw_rect(Rect2(base + Vector2(-4, -22), Vector2(8, 16)), Color("c8ccd2"))
	draw_rect(Rect2(base + Vector2(-14, -40), Vector2(28, 20)), Color("ff7eb6"))
	draw_rect(Rect2(base + Vector2(-10, -46), Vector2(20, 6)), Color("2c2c34"))
