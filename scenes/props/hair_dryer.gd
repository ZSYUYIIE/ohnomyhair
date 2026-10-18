class_name HairDryer
extends Area2D
## Floor-standing salon blow dryer: a column of warm air above it. Position is the
## column's top-left corner; the dryer sits at its bottom center.
## - A gliding twin-tails rises (to the top of the column, then bobs there).
##   Carrying a friend she still rises, just slower (the friend's weight).
## - Anyone else falls slower in the warm air.
## - Everyone inside is dried instantly (shampoo showers make you wet) - unless a running
##   shower is pouring on them at the same time.
## Combo "Hair-copter": pompadour stands on the gliding twin-tails' head and rides up at
## full speed - faster than being carried.

@export var size := Vector2(64, 320)
@export var lift_speed := 300.0
@export var carry_lift_speed := 160.0
@export var lift_accel := 1800.0
@export var warm_fall_speed := 260.0

const ART := preload("res://assets/art/props/prop_dryer.png")

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
	# Warm air: faint cream streaks rising up the column (motion stays in code).
	var streaks := int(size.x / 16.0)
	for i in streaks:
		var x := 8.0 + i * 16.0
		var y := size.y - fmod(_t * 220.0 + i * 57.0, size.y)
		draw_line(Vector2(x, y), Vector2(x + sin(_t * 6.0 + i) * 3.0, y - 26.0), Color(1, 0.95, 0.85, 0.5), 3.0)
	draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.85, 0.6, 0.06))
	draw_texture(ART, Vector2(size.x / 2.0 - 32.0, size.y - 64.0))
