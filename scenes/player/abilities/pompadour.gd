class_name Pompadour
extends HairAbility
## Pompadour "The Parry".
## Skill: launch a friend standing on your head; otherwise dash forward, smashing
## hair-gel walls and ramming enemies. One dash per jump in the air (landing recharges
## it): chained air dashes zero the fall each time and let her hover over any gap.
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
var _parry_pose := 0.0  # how long the parry animation still shows
var _cannonball := false
var _air_dash_used := false


func _init() -> void:
	body_color = Color("a9d4ff")
	display_name = "Pompadour"
	frames = preload("res://assets/art/characters/pompadour/frames.tres")


func tick(delta: float) -> void:
	_cooldown -= delta
	if player.is_on_floor():
		_air_dash_used = false
	if player.pressed("skill"):
		var rider := _rider()
		var base := player.teammate()
		var waiting_for_spring: bool = base != null and base.ability.has_method("is_charging") and base.ability.is_charging() and base.has_rider(player)
		if waiting_for_spring:
			pass  # Holding skill on a charging Afro arms the co-op cannonball.
		elif rider:
			rider.launch(launch_height)
			player.bounce(Vector2(1.3, 0.7))
		elif _cooldown <= 0.0 and player.carried_by == null and (player.is_on_floor() or not _air_dash_used):
			_air_dash_used = not player.is_on_floor()
			_start_dash(player.facing, dash_time)

	if _dash_left > 0.0:
		_dash_left -= delta
		if _dash_left <= 0.0:
			_slinging = false
		player.velocity = Vector2(_dash_dir * dash_speed, 0.0)
		strike(_struck, 2 if _cannonball else 1, 3.0 if _cannonball else 0.3, Vector2(480.0 if _cannonball else 320.0, -160.0))
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
		_air_dash_used = true  # the fling is her air dash for this flight
		return
	tick_attack(delta)


func is_slinging() -> bool:
	return _slinging


func _start_dash(direction: float, seconds: float) -> void:
	_cannonball = false
	_dash_left = seconds
	_dash_dir = direction
	_cooldown = dash_cooldown
	_struck.clear()


## Afro charges underneath a rider; that rider holds skill as Afro releases.
func spring_launch(direction: float) -> void:
	_start_dash(direction, 0.5)
	_cannonball = true
	_slinging = true
	player.bounce(Vector2(1.4, 0.7))
	player.make_invincible(0.35)


## Parry also works while dangling from twin-tails' hair.
func tick_attack(delta: float) -> void:
	_parry_cooldown -= delta
	_parry_pose -= delta
	if player.pressed("attack") and _parry_cooldown <= 0.0:
		_parry_pose = 0.3
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


func anim() -> StringName:
	if _dash_left > 0.0:
		return &"dash"
	if _parry_pose > 0.0:
		return &"parry"
	return &""


func is_driving() -> bool:
	return _dash_left > 0.0


func after_move() -> void:
	if _dash_left <= 0.0:
		return
	for i in player.get_slide_collision_count():
		var collider := player.get_slide_collision(i).get_collider()
		if collider and collider.has_method("smash") and not player.is_wet():
			collider.smash(_cannonball)
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
	_cannonball = false
	_dash_left = 0.0
	_slinging = false
	_cooldown = 0.0
	_parry = 0.0
	_parry_pose = 0.0
	_air_dash_used = false


func _rider() -> Player:
	var mate := player.teammate()
	if mate and mate.alive and mate.carried_by == null and player.has_rider(mate):
		return mate
	return null

