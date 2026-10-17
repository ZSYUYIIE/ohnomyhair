extends HairAbility
## Pompadour "The Parry": press skill to dash forward and smash hair-gel walls.
## If your friend is standing on your head, the same press launches them upward.

const HAIR_COLOR := Color("3a8fd6")

@export var dash_speed := 720.0
@export var dash_time := 0.16
@export var dash_cooldown := 0.4
@export var launch_height := 224.0  # 7 tiles above your head

var _dash_left := 0.0
var _dash_dir := 1.0
var _cooldown := 0.0


func _init() -> void:
	body_color = Color("a9d4ff")


func tick(delta: float) -> void:
	_cooldown -= delta
	if player.pressed("skill"):
		var rider := _rider()
		if rider:
			rider.launch(launch_height)
		elif _cooldown <= 0.0 and player.carried_by == null:
			_dash_left = dash_time
			_dash_dir = player.facing
			_cooldown = dash_cooldown

	if _dash_left > 0.0:
		_dash_left -= delta
		player.velocity = Vector2(_dash_dir * dash_speed, 0.0)
	queue_redraw()


func is_driving() -> bool:
	return _dash_left > 0.0


func after_move() -> void:
	if _dash_left <= 0.0:
		return
	for i in player.get_slide_collision_count():
		var collider := player.get_slide_collision(i).get_collider()
		if collider and collider.has_method("smash"):
			collider.smash()
			_dash_left = 0.0
	if player.is_on_wall():
		_dash_left = 0.0


func reset() -> void:
	_dash_left = 0.0
	_cooldown = 0.0
	queue_redraw()


func _rider() -> Player:
	for body in player.head_pad.get_overlapping_bodies():
		# Must really be standing on top: a friend overlapping us (e.g. right after a carry) doesn't count.
		var on_top: bool = body.global_position.y < player.global_position.y - Player.HALF_SIZE.y
		if body is Player and body != player and body.alive and body.carried_by == null and body.is_on_floor() and on_top:
			return body
	return null


func _draw() -> void:
	var top := -Player.HALF_SIZE.y
	# The pompadour: a hard wedge sticking out forward (+x is always "forward" here).
	var wedge := PackedVector2Array([Vector2(-14, top + 4), Vector2(-10, top - 8), Vector2(30, top - 4), Vector2(14, top + 6)])
	draw_colored_polygon(wedge, HAIR_COLOR)
	if _dash_left > 0.0:
		for i in 3:
			var x := -24.0 - i * 10.0
			draw_line(Vector2(x, top + 10 + i * 8), Vector2(x - 14, top + 10 + i * 8), HAIR_COLOR, 3.0)
