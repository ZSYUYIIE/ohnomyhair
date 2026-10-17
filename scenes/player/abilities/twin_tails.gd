class_name TwinTails
extends HairAbility
## Player A "The Helicopter": hold skill to glide, press skill near a lever to pull it,
## attack = hair whip that stuns enemies for 1 s without damage (PLAN.md 1.1).

const GLIDE_FALL_SPEED := 60.0
const LEVER_REACH := 24.0
const WHIP_TIME := 0.12
const WHIP_COOLDOWN := 0.35
const WHIP_STUN := 1.0
const HAIR_COLOR := Color("8c1c4f")

var gliding := false

var _whip := 0.0
var _whip_cooldown := 0.0
var _whipped: Array[Node] = []


func tick(delta: float) -> void:
	_whip_cooldown -= delta
	if Input.is_action_just_pressed(player.act("skill")):
		var lever := _lever_in_reach()
		if lever:
			lever.interact(player)

	gliding = Input.is_action_pressed(player.act("skill")) and player.velocity.y > 0.0
	if gliding:
		player.max_fall_speed = GLIDE_FALL_SPEED

	if Input.is_action_just_pressed(player.act("attack")) and _whip_cooldown <= 0.0:
		_whip = WHIP_TIME
		_whip_cooldown = WHIP_COOLDOWN
		_whipped.clear()
	if _whip > 0.0:
		_whip -= delta
		for body in player.hit_box.get_overlapping_bodies():
			if body.has_method("take_hit") and body not in _whipped:
				_whipped.append(body)
				body.take_hit(0, WHIP_STUN)


func _lever_in_reach() -> Lever:
	for lever in player.get_tree().get_nodes_in_group("levers"):
		if lever.global_position.distance_to(player.global_position) <= LEVER_REACH:
			return lever
	return null


func draw_hair(canvas: CanvasItem) -> void:
	if gliding:
		var spin := 1.0 if int(Time.get_ticks_msec() / 80) % 2 == 0 else -1.0
		canvas.draw_rect(Rect2(-16, -25 + spin, 10, 3), HAIR_COLOR)
		canvas.draw_rect(Rect2(6, -25 - spin, 10, 3), HAIR_COLOR)
	else:
		canvas.draw_rect(Rect2(-10, -22, 4, 12), HAIR_COLOR)
		canvas.draw_rect(Rect2(6, -22, 4, 12), HAIR_COLOR)
	canvas.draw_rect(Rect2(-6, -24, 12, 3), HAIR_COLOR)
	if _whip > 0.0:
		var f := player.facing
		canvas.draw_line(Vector2(6 * f, -16), Vector2(24 * f, -10), Color.WHITE, 2.0)
