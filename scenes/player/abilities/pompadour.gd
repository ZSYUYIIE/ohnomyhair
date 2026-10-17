class_name Pompadour
extends HairAbility
## Pompadour "The Parry".
## Skill: launch a friend standing on your head; otherwise dash forward, smashing
## hair-gel walls and ramming enemies.
## Attack: parry (0.15 s window) that sends scissors back the way they came.
## Combo "Sling Dash": press skill while dangling from twin-tails' hair to be flung
## forward: a long, gravity-free air dash that smashes gel; the carrier bobs up.
## Wet (shampoo shower): the pompadour flops, and a dash just bounces off gel until dried.

const HAIR_COLOR := Color("3a8fd6")

@export var dash_speed := 720.0
@export var dash_time := 0.16
@export var dash_cooldown := 0.4
@export var launch_height := 256.0  # rider rises 8 tiles above your head
@export var parry_window := 0.15
@export var sling_time := 0.3      # vs dash_time 0.16: the fling carries ~1.9x as far
@export var sling_lift := 300.0    # carrier's upward bob when the weight comes off
@export var parry_cooldown := 0.4

var _dash_left := 0.0
var _dash_dir := 1.0
var _slinging := false
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
			_start_dash(player.facing, dash_time)

	if _dash_left > 0.0:
		_dash_left -= delta
		if _dash_left <= 0.0:
			_slinging = false
		player.velocity = Vector2(_dash_dir * dash_speed, 0.0)
		strike(_struck, 1, 0.3, Vector2(320.0, -160.0))
	tick_attack(delta)


## While carried: skill = sling dash (let go and get flung), attack = parry as usual.
func tick_carried(delta: float) -> void:
	_cooldown -= delta
	var carrier := player.carried_by
	if player.pressed("skill") and _cooldown <= 0.0:
		# Start from where she hangs (drawn CARRY_HANG below), unless that's inside a wall.
		var from := carrier.global_position
		if not carrier.is_on_floor() and not player.test_move(Transform2D(0.0, from), Player.CARRY_HANG):
			from += Player.CARRY_HANG
		carrier.drop()
		player.global_position = from
		carrier.velocity.y = minf(carrier.velocity.y, -sling_lift)
		_start_dash(carrier.facing, sling_time)
		_slinging = true
		return
	tick_attack(delta)


func is_slinging() -> bool:
	return _slinging


func _start_dash(direction: float, seconds: float) -> void:
	_dash_left = seconds
	_dash_dir = direction
	_cooldown = dash_cooldown
	_struck.clear()


## Parry also works while dangling from twin-tails' hair.
func tick_attack(delta: float) -> void:
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
		if collider and collider.has_method("smash") and not player.is_wet():
			collider.smash()
			# A sling dash punches straight through gel; a ground dash stops at the wall.
			if not _slinging:
				_dash_left = 0.0
	if player.is_on_wall() and not (_slinging and _touching_gel() and not player.is_wet()):
		_dash_left = 0.0
		_slinging = false


func _touching_gel() -> bool:
	for i in player.get_slide_collision_count():
		var collider := player.get_slide_collision(i).get_collider()
		if collider and collider.has_method("smash"):
			return true
	return false


func reset() -> void:
	_dash_left = 0.0
	_slinging = false
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
	# Hair is the health bar: each hit trims the wedge. Wet, it flops down over the face.
	var reach := 14.0 + 16.0 * player.hair_left()
	var hair := HAIR_COLOR.darkened(0.25) if player.is_wet() else HAIR_COLOR
	var wedge := PackedVector2Array([Vector2(-14, top + 4), Vector2(-10, top - 8), Vector2(reach, top - 4), Vector2(14, top + 6)])
	if player.is_wet():
		wedge = PackedVector2Array([Vector2(-14, top + 4), Vector2(-10, top - 6), Vector2(reach - 4, top + 2), Vector2(reach - 8, top + 16)])
	draw_colored_polygon(wedge, hair)
	if _dash_left > 0.0:
		for i in 3:
			var x := -24.0 - i * 10.0
			draw_line(Vector2(x, top + 10 + i * 8), Vector2(x - 14, top + 10 + i * 8), HAIR_COLOR, 3.0)
	if _parry > 0.0:
		draw_arc(Vector2(20, 0), 24.0, -PI / 2, PI / 2, 12, Color.WHITE, 4.0)
