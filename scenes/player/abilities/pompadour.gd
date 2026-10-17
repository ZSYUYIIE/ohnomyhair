class_name Pompadour
extends HairAbility
## Player B "The Parry": skill = launch a teammate standing on your head, otherwise dash;
## attack = parry (0.15 s window) that sends scissors back the way they came (PLAN.md 1.1, 2.6).

const DASH_SPEED := 330.0
const DASH_TIME := 0.16
const DASH_COOLDOWN := 0.5
const PARRY_WINDOW := 0.15
const PARRY_COOLDOWN := 0.4
const LAUNCH_MULTIPLIER := 1.6
const HAIR_COLOR := Color("a35a00")

var _dash := 0.0
var _dash_cooldown := 0.0
var _parry := 0.0
var _parry_cooldown := 0.0
var _struck: Array[Node] = []


func tick(delta: float) -> void:
	_dash_cooldown -= delta
	_parry_cooldown -= delta

	if Input.is_action_just_pressed(player.act("skill")):
		var rider := rider_on_head()
		if rider:
			launch(rider)
		elif _dash_cooldown <= 0.0:
			_dash = DASH_TIME
			_dash_cooldown = DASH_COOLDOWN
			_struck.clear()
	if _dash > 0.0:
		_dash -= delta
		player.velocity.x = player.facing * DASH_SPEED
		player.control_lock = 0.05
		_strike(1, 0.3, Vector2(player.facing * 160.0, -80.0))

	if Input.is_action_just_pressed(player.act("attack")) and _parry_cooldown <= 0.0:
		_parry = PARRY_WINDOW
		_parry_cooldown = PARRY_COOLDOWN
		_struck.clear()
	if _parry > 0.0:
		_parry -= delta
		for area in player.hit_box.get_overlapping_areas():
			if area is Scissor and not area.deflected:
				area.deflect()
				Game.hit_stop(0.05)
		_strike(1, 0.2, Vector2(player.facing * 120.0, -60.0))


## The teammate counts as "on my head" when standing on my head pad.
func rider_on_head() -> Player:
	var mate := player.teammate()
	if mate == null or not mate.is_on_floor():
		return null
	var feet := player.global_position + Vector2(0, Player.HEAD_TOP)
	if absf(mate.global_position.x - feet.x) < 10.0 and absf(mate.global_position.y - feet.y) < 4.0:
		return mate
	return null


func launch(mate: Player) -> void:
	mate.velocity.y = mate.jump_velocity * LAUNCH_MULTIPLIER
	mate.launched = true


func _strike(damage: int, stun: float, knockback: Vector2) -> void:
	for body in player.hit_box.get_overlapping_bodies():
		if body.has_method("take_hit") and body not in _struck:
			_struck.append(body)
			body.take_hit(damage, stun, knockback)


func draw_hair(canvas: CanvasItem) -> void:
	var f := player.facing
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(-6 * f, -22), Vector2(-4 * f, -27), Vector2(16 * f, -26), Vector2(6 * f, -20),
	]), HAIR_COLOR)
	if _parry > 0.0:
		var start := -PI / 2 if f > 0.0 else PI / 2
		canvas.draw_arc(Vector2(10 * f, -12), 12.0, start, start + PI, 8, Color.WHITE, 2.0)
