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


func _init() -> void:
	body_color = Color("ffb3d1")
	display_name = "Twin-Tails"


func tick(delta: float) -> void:
	_tick_catch()
	if player.pressed("skill") and _held == null and not _pull_lever():
		_grab_friend()
	if player.carrying and not player.held("skill"):
		player.drop()

	var gliding := player.held("skill") and not player.is_on_floor() and not player.is_wet()
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
	if player.pressed("attack") and _whip_cooldown <= 0.0:
		_whip = whip_time
		_whip_cooldown = whip_cooldown
		_whipped.clear()
	if _whip > 0.0:
		_whip -= delta
		strike(_whipped, 0, whip_stun, Vector2.ZERO)
	queue_redraw()


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


func reset() -> void:
	if _held and is_instance_valid(_held):
		_held.queue_free()
	_held = null
	_gliding = false
	_spin = 0.0
	_whip = 0.0
	queue_redraw()


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
		# Only a friend beside me, at about my height: one standing on my head (or above
		# it) isn't grabbed, so pressing skill there means glide - the hair-copter.
		var beside := absf(body.global_position.y - player.global_position.y) < Player.HALF_SIZE.y
		if body is Player and body != player and body.alive and body.carried_by == null and body.carrying == null and beside:
			player.grab(body)
			return


func _draw() -> void:
	var top := -Player.HALF_SIZE.y
	# Hair is the health bar: the tails get shorter with every hit.
	var tail := 18.0 * player.hair_left()
	var hair := HAIR_COLOR.darkened(0.25) if player.is_wet() else HAIR_COLOR
	if _spin > 0.0:
		# Propeller: two tails spinning above the head.
		for i in 2:
			var a := _spin + PI * i
			var tip := Vector2(cos(a) * (4.0 + tail), top - 6.0 + sin(a) * 4.0)
			draw_line(Vector2(0, top - 6.0), tip, hair, 6.0)
		draw_circle(Vector2(0, top - 6.0), 4.0, hair)
	elif player.is_wet():
		# Soaked: the tails hang flat and long against the body.
		draw_rect(Rect2(-19, top + 2, 5, tail + 10), hair)
		draw_rect(Rect2(14, top + 2, 5, tail + 10), hair)
	else:
		draw_rect(Rect2(-20, top + 2, 6, tail), hair)
		draw_rect(Rect2(14, top + 2, 6, tail), hair)
	draw_rect(Rect2(-14, top - 4, 28, 8), hair)
	if _whip > 0.0:
		draw_line(Vector2(12, top + 10), Vector2(48, top + 22), Color.WHITE, 4.0)
	if is_holding_scissor():
		# Pigtails reaching up around the caught scissor.
		draw_line(Vector2(-16, top + 4), Vector2(-8, top - 24), hair, 5.0)
		draw_line(Vector2(16, top + 4), Vector2(8, top - 24), hair, 5.0)
	if player.carrying:
		var target := to_local(player.carrying.visual.global_position + Vector2(0, -Player.HALF_SIZE.y))
		draw_line(Vector2(0, top), target, HAIR_COLOR, 4.0)
