class_name Pompadour
extends HairAbility
## Pompadour "The Parry".
## Skill: launch a friend standing on your head; otherwise dash forward, smashing
## hair-gel walls and ramming enemies.
## Attack: parry (0.15 s window) that sends scissors back the way they came.

const HAIR_COLOR := Color("3a8fd6")

@export var dash_speed := 720.0
@export var dash_time := 0.16
@export var dash_cooldown := 0.4
@export var launch_height := 256.0  # rider rises 8 tiles above your head
@export var parry_window := 0.15
@export var parry_cooldown := 0.4

var _dash_left := 0.0
var _dash_dir := 1.0
var _cooldown := 0.0
var _parry := 0.0
var _parry_cooldown := 0.0
var _struck: Array[Node] = []


func _init() -> void:
	body_color = Color("a9d4ff")
	display_name = "Pompadour"


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
			_struck.clear()

	if _dash_left > 0.0:
		_dash_left -= delta
		player.velocity = Vector2(_dash_dir * dash_speed, 0.0)
		strike(_struck, 1, 0.3, Vector2(320.0, -160.0))

	_parry_cooldown -= delta
	if player.pressed("attack") and _parry_cooldown <= 0.0:
		_parry = parry_window
		_parry_cooldown = parry_cooldown
		_struck.clear()
	if _parry > 0.0:
		_parry -= delta
		for area in player.hit_box.get_overlapping_areas():
			if area is Scissor and not area.deflected:
				area.deflect()
				player.hit_stop(0.05)
		strike(_struck, 1, 0.2, Vector2(240.0, -120.0))
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
	_parry = 0.0
	queue_redraw()


func _rider() -> Player:
	var mate := player.teammate()
	if mate and mate.alive and mate.carried_by == null and player.has_rider(mate):
		return mate
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
	if _parry > 0.0:
		draw_arc(Vector2(20, 0), 24.0, -PI / 2, PI / 2, 12, Color.WHITE, 4.0)
