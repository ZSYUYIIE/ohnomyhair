class_name TwinTails
extends HairAbility
## Twin-tails "The Helicopter".
## Skill (hold): glide. Press next to a lever to pull it, or next to your friend to
## grab them and carry them while gliding.
## Attack: hair whip that stuns enemies for 1 s without damage.
## Combo "Volley": whipping a scissor that pompadour already parried (blue) sends it
## straight up as a golden scissor. The whip reaches above the head, so twin-tails
## can wait in a trench while enemy scissors fly over her.

const HAIR_COLOR := Color("ff5fa2")

@export var glide_fall_speed := 120.0
@export var carry_fall_speed := 220.0
@export var whip_time := 0.12
@export var whip_cooldown := 0.35
@export var whip_stun := 1.0
@export var volley_reach := Vector2(52, 84)  # half-width; height above the head

var _spin := 0.0
var _whip := 0.0
var _whip_cooldown := 0.0
var _whipped: Array[Node] = []
var _pose := &""        # one-shot animation (attack / pull) and how long it still shows
var _pose_left := 0.0


func _init() -> void:
	body_color = Color("ffb3d1")
	display_name = "Twin-Tails"
	frames = preload("res://assets/art/characters/twin_tails/frames.tres")


func tick(delta: float) -> void:
	if player.pressed("skill"):
		if _pull_lever():
			_show(&"pull", 0.4)
		else:
			_grab_friend()
	if player.carrying and not player.held("skill"):
		player.drop()

	var gliding := player.held("skill") and not player.is_on_floor()
	if gliding:
		player.fall_cap = carry_fall_speed if player.carrying else glide_fall_speed
		_spin += delta * 30.0
	else:
		_spin = 0.0
	tick_attack(delta)


## The whip also works while dangling from a friend's hair.
func tick_attack(delta: float) -> void:
	_whip_cooldown -= delta
	_pose_left -= delta
	if player.pressed("attack") and _whip_cooldown <= 0.0:
		_show(&"attack", 0.3)
		_whip = whip_time
		_whip_cooldown = whip_cooldown
		_whipped.clear()
	if _whip > 0.0:
		_whip -= delta
		strike(_whipped, 0, whip_stun, Vector2.ZERO)
		for scissor: Scissor in player.get_tree().get_nodes_in_group("scissors"):
			if scissor.deflected and not scissor.golden and _in_volley_reach(scissor.global_position):
				scissor.volley(player.global_position.x)
				player.hit_stop(0.06)


func _in_volley_reach(pos: Vector2) -> bool:
	var rel := pos - player.global_position
	return absf(rel.x) <= volley_reach.x and rel.y <= Player.HALF_SIZE.y and rel.y >= -Player.HALF_SIZE.y - volley_reach.y


func anim() -> StringName:
	if _pose_left > 0.0:
		return _pose
	if _spin > 0.0:
		return &"carry_glide" if player.carrying else &"glide"
	return &""


func _show(pose: StringName, seconds: float) -> void:
	_pose = pose
	_pose_left = seconds


func reset() -> void:
	_spin = 0.0
	_whip = 0.0
	_pose_left = 0.0


func _pull_lever() -> bool:
	for area in player.interact_area.get_overlapping_areas():
		if area.has_method("interact"):
			area.interact(player)
			return true
	return false


func _grab_friend() -> void:
	if player.carrying:
		return
	for body in player.interact_area.get_overlapping_bodies():
		if body is Player and body != player and body.alive and body.carried_by == null and body.carrying == null:
			player.grab(body)
			return

