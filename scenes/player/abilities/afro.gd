extends HairAbility
## Charge a spring for a rider; hold attack for a timed shield and a two-player return.
const HAIR_COLOR := Color("ee9a42")
@export var charge_time := 0.75
@export var bounce_height := 320.0
var charge := 0.0
var _spring_cooldown := 0.0
var _guard := 0.0
var _guard_cooldown := 0.0
var _bracing := false
var _held: Scissor

func _init() -> void:
	display_name = "Afro"
	body_color = Color("ffe1b4")
	frames = load("res://assets/art/characters/afro/frames.tres")

func tick(delta: float) -> void:
	_spring_cooldown = maxf(0, _spring_cooldown - delta)
	if player.is_wet():
		charge = 0
		_bracing = false
	else:
		_bracing = player.held("skill") and player.is_on_floor()
		if _bracing:
			charge = minf(charge_time, charge + delta)
		if not player.held("skill") and charge > 0:
			var rider := player._rider_on_head()
			if rider and charge >= 0.2 and _spring_cooldown <= 0:
				if rider.ability.has_method("spring_launch") and rider.held("skill"):
					rider.ability.spring_launch(player.facing)
				else:
					rider.launch(bounce_height + charge / charge_time * 64)
				player.bounce(Vector2(1.4, 0.65))
				_spring_cooldown = 0.5
			charge = 0
		if not player.held("skill"):
			charge = 0
	tick_attack(delta)
	queue_redraw()

func tick_attack(delta: float) -> void:
	queue_redraw()
	_guard = maxf(0, _guard - delta)
	_guard_cooldown = maxf(0, _guard_cooldown - delta)
	if is_instance_valid(_held):
		if not player.held("attack") or player.is_wet():
			_held.return_from_afro(player.facing)
			_held = null
	elif player.pressed("attack") and _guard_cooldown <= 0 and not player.is_wet():
		_guard = 0.8
		_guard_cooldown = 1.2
	if player.held("attack") and not player.is_wet() and not is_instance_valid(_held):
		for scissor: Scissor in player.get_tree().get_nodes_in_group("scissors"):
			if scissor.deflected and not scissor.golden and scissor.holder == null and scissor.global_position.distance_to(player.global_position + Vector2(0, -26)) < 54:
				scissor.catch_by(player)
				_held = scissor
				break

func tick_carried(delta: float) -> void:
	charge = 0
	_bracing = false
	tick_attack(delta)

func block_hit() -> bool:
	if _guard > 0 and not player.is_wet():
		player.bounce(Vector2(1.2, 0.85))
		return true
	return false

func is_charging() -> bool:
	return player.held("skill") and player.is_on_floor() and not player.is_wet()

func move_multiplier() -> float:
	return 0.25 if _bracing else 1.0

func anim() -> StringName:
	if player.is_wet(): return &"wet"
	if _bracing: return &"bounce"
	if _guard > 0 or is_instance_valid(_held): return &"guard"
	return &""

func reset() -> void:
	if is_instance_valid(_held): _held.queue_free()
	_held = null
	charge = 0
	_bracing = false
	_guard = 0
	_guard_cooldown = 0
	_spring_cooldown = 0

func _draw() -> void:
	if charge > 0:
		draw_arc(Vector2(0, -24), 34, -PI / 2, -PI / 2 + TAU * charge / charge_time, 24, HAIR_COLOR, 4, true)
	if _guard > 0:
		draw_arc(Vector2(0, -10), 38, -PI * 0.7, PI * 0.7, 24, Color("f1c40f"), 4, true)
