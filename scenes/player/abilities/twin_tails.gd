class_name TwinTails
extends HairAbility
## Twin-tails "The Helicopter".
## Skill (hold): glide. Press next to a lever to pull it, or next to your friend to
## grab them and carry them while gliding.
## Attack: hair whip that stuns enemies for 1 s without damage. It never touches scissors:
## parrying is pompadour's job alone.
## Combo "Hair Catch": while she stands and holds skill her pigtails are open; a scissor pompadour
## already parried (blue) that flies into them is caught and held. Letting go of skill
## tosses it straight up as a golden scissor (rings service bells). The pigtails reach
## above her head, so she can wait in a trench while enemy scissors fly over her.
## Enemy (red) scissors can't be caught - they still hurt. In the air, skill only glides
## (so she never snatches the scissors her friend is parrying at a boss).
## Wet (shampoo shower): the tails are too heavy to spin, so no gliding until dried.

const HAIR_COLOR := Color("ff5fa2")
const PullFrames := preload("res://scenes/player/pull_frames.gd")

@export var glide_fall_speed := 120.0
@export var carry_fall_speed := 220.0
@export var whip_time := 0.12
@export var whip_cooldown := 0.35
@export var whip_stun := 1.0
@export var catch_reach := Vector2(52, 84)  # half-width; height above the head

var _spin := 0.0
var _gliding := false
var _held: Scissor = null
var _whip := 0.0
var _whip_cooldown := 0.0
var _whipped: Array[Node] = []
var _pose := &""        # one-shot animation (attack / pull) and how long it still shows
var _pose_left := 0.0


func _init() -> void:
	body_color = Color("ffb3d1")
	display_name = "Twin-Tails"
	frames = PullFrames.get_frames()


func tick(delta: float) -> void:
	_tick_catch()
	if player.pressed("skill") and _held == null:
		if _pull_lever():
			_show(&"pull", 0.4)
		else:
			_grab_friend()
	if player.carrying and not player.held("skill"):
		player.drop()

	var gliding := player.held("skill") and not player.is_on_floor() and not player.is_wet()
	if gliding and not _gliding:
		Sound.play("glide", 0.1, -3.0)
	_gliding = gliding
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
		Sound.play("whip")
		_whip = whip_time
		_whip_cooldown = whip_cooldown
		_whipped.clear()
	if _whip > 0.0:
		_whip -= delta
		strike(_whipped, 0, whip_stun, Vector2.ZERO)



## Hair Catch: open pigtails (skill held) catch a parried scissor; letting go tosses it up.
func _tick_catch() -> void:
	if _held and not is_instance_valid(_held):
		_held = null
	if _held:
		if not player.held("skill"):
			_held.toss(player.global_position.x)
			_held = null
			player.hit_stop(0.05)
		return
	if not player.held("skill") or player.carrying or not player.is_on_floor():
		return
	for scissor: Scissor in player.get_tree().get_nodes_in_group("scissors"):
		if scissor.deflected and not scissor.golden and scissor.holder == null and in_catch_reach(scissor.global_position):
			scissor.catch_by(player)
			_held = scissor
			return


func in_catch_reach(pos: Vector2) -> bool:
	var rel := pos - player.global_position
	return absf(rel.x) <= catch_reach.x and rel.y <= Player.HALF_SIZE.y and rel.y >= -Player.HALF_SIZE.y - catch_reach.y


func is_holding_scissor() -> bool:
	return _held != null and is_instance_valid(_held)


func is_gliding() -> bool:
	return _gliding


func anim() -> StringName:
	if is_holding_scissor():
		return &"pull"   # arms up, holding the caught scissor overhead
	if _pose_left > 0.0:
		return _pose
	if _spin > 0.0:
		return &"carry_glide" if player.carrying else &"glide"
	return &""


func _show(pose: StringName, seconds: float) -> void:
	_pose = pose
	_pose_left = seconds
	# A second accepted pull restarts the motion, even during the previous pull.
	player.sprite.play(pose)
	player.sprite.set_frame_and_progress(0, 0.0)


func frame_scale(animation: StringName) -> float:
	return PullFrames.SCALE if animation == &"pull" else 1.0


func frame_material(animation: StringName) -> Material:
	return PullFrames.MATERIAL if animation == &"pull" else null


func reset() -> void:
	if _held and is_instance_valid(_held):
		_held.queue_free()
	_held = null
	_gliding = false
	_spin = 0.0
	_whip = 0.0
	_pose_left = 0.0


func _pull_lever() -> bool:
	var nearest: Lever = null
	var distance := INF
	for area in player.interact_area.get_overlapping_areas():
		if area is Lever and area.can_interact():
			var next_distance: float = player.global_position.distance_squared_to(area.global_position)
			if next_distance < distance:
				nearest = area
				distance = next_distance
	if nearest == null or not nearest.interact(player): return false
	var direction := signf(nearest.global_position.x - player.global_position.x)
	if direction != 0.0:
		player.facing = direction
		player.visual.scale.x = direction
	return true


func _grab_friend() -> void:
	if player.carrying:
		return
	for body in player.interact_area.get_overlapping_bodies():
		# Only a friend beside me, at about my height: one standing on my head (or above
		# it) isn't grabbed, so pressing skill there means glide - the hair-copter.
		var beside := absf(body.global_position.y - player.global_position.y) < Player.HALF_SIZE.y
		if body is Player and body != player and body.alive and body.carried_by == null and body.carrying == null and beside:
			player.grab(body)
			return

