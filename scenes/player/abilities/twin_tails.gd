class_name TwinTails
extends HairAbility
## Twin-tails "The Helicopter".
## Skill (hold): glide. Press next to a lever to pull it, or next to your friend to
## grab them and carry them while gliding.
## Attack: hair whip that stuns enemies for 1 s without damage.

const HAIR_COLOR := Color("ff5fa2")

@export var glide_fall_speed := 120.0
@export var carry_fall_speed := 220.0
@export var whip_time := 0.12
@export var whip_cooldown := 0.35
@export var whip_stun := 1.0

var _spin := 0.0
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

	var gliding := player.held("skill") and not player.is_on_floor()
	if gliding:
		player.fall_cap = carry_fall_speed if player.carrying else glide_fall_speed
		_spin += delta * 30.0
	else:
		_spin = 0.0

	_whip_cooldown -= delta
	if player.pressed("attack") and _whip_cooldown <= 0.0:
		_whip = whip_time
		_whip_cooldown = whip_cooldown
		_whipped.clear()
	if _whip > 0.0:
		_whip -= delta
		strike(_whipped, 0, whip_stun, Vector2.ZERO)
	queue_redraw()


func reset() -> void:
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
		if body is Player and body != player and body.alive and body.carried_by == null and body.carrying == null:
			player.grab(body)
			return


func _draw() -> void:
	var top := -Player.HALF_SIZE.y
	if _spin > 0.0:
		# Propeller: two tails spinning above the head.
		for i in 2:
			var a := _spin + PI * i
			var tip := Vector2(cos(a) * 22.0, top - 6.0 + sin(a) * 4.0)
			draw_line(Vector2(0, top - 6.0), tip, HAIR_COLOR, 6.0)
		draw_circle(Vector2(0, top - 6.0), 4.0, HAIR_COLOR)
	else:
		draw_rect(Rect2(-20, top + 2, 6, 18), HAIR_COLOR)
		draw_rect(Rect2(14, top + 2, 6, 18), HAIR_COLOR)
	draw_rect(Rect2(-14, top - 4, 28, 8), HAIR_COLOR)
	if _whip > 0.0:
		draw_line(Vector2(12, top + 10), Vector2(48, top + 22), Color.WHITE, 4.0)
	if player.carrying:
		var target := to_local(player.carrying.visual.global_position + Vector2(0, -Player.HALF_SIZE.y))
		draw_line(Vector2(0, top), target, HAIR_COLOR, 4.0)
