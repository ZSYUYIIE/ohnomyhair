class_name TwinTails
extends HairAbility
## Twin-tails "The Helicopter".
## Skill (hold): glide. Press next to a lever to pull it, or next to your friend to
## grab them and carry them while gliding.
## Attack: hair whip that stuns enemies for 1 s without damage.
## Combo "Volley": whipping a scissor that pompadour already parried (blue) sends it
## straight up as a golden scissor. The whip reaches above the head, so twin-tails
## can wait in a trench while enemy scissors fly over her.
## Wet (shampoo shower): the tails are too heavy to spin, so no gliding until dried.

const HAIR_COLOR := Color("ff5fa2")

@export var glide_fall_speed := 120.0
@export var carry_fall_speed := 220.0
@export var whip_time := 0.12
@export var whip_cooldown := 0.35
@export var whip_stun := 1.0
@export var volley_reach := Vector2(52, 84)  # half-width; height above the head

var _spin := 0.0
var _gliding := false
var _whip := 0.0
var _whip_cooldown := 0.0
var _whipped: Array[Node] = []


func _init() -> void:
	body_color = Color("ffb3d1")
	display_name = "Twin-Tails"


func tick(delta: float) -> void:
	if player.pressed("skill") and not _pull_lever():
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
		for scissor: Scissor in player.get_tree().get_nodes_in_group("scissors"):
			if scissor.deflected and not scissor.golden and _in_volley_reach(scissor.global_position):
				scissor.volley(player.global_position.x)
				player.hit_stop(0.06)
	queue_redraw()


func _in_volley_reach(pos: Vector2) -> bool:
	var rel := pos - player.global_position
	return absf(rel.x) <= volley_reach.x and rel.y <= Player.HALF_SIZE.y and rel.y >= -Player.HALF_SIZE.y - volley_reach.y


func is_gliding() -> bool:
	return _gliding


func reset() -> void:
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
		# A friend riding on my head isn't grabbed: pressing skill there means glide (hair-copter).
		if body is Player and body != player and body.alive and body.carried_by == null and body.carrying == null and not player.has_rider(body):
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
		draw_arc(Vector2(0, top), volley_reach.x, PI * 1.1, PI * 1.9, 10, Color(1, 1, 1, 0.6), 3.0)
	if player.carrying:
		var target := to_local(player.carrying.visual.global_position + Vector2(0, -Player.HALF_SIZE.y))
		draw_line(Vector2(0, top), target, HAIR_COLOR, 4.0)
