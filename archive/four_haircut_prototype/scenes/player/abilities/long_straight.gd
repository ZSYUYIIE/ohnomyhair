extends HairAbility
## A grounded friend lowers a climbable rope. In air, skill hooks visible gold rings.
const HAIR_COLOR := Color("9467d5")
@export var rope_length := 320.0
@export var hook_reach := 300.0
@export var lasso_reach := 200.0
var _rope := false
var _hook: Node2D
var _lasso_time := 0.0
var _lasso_end := Vector2.ZERO
var _cooldown := 0.0

func _init() -> void:
	display_name = "Long Straight"
	body_color = Color("e2d1fa")
	frames = load("res://assets/art/characters/long_straight/frames.tres")

func tick(delta: float) -> void:
	_rope = player.held("skill") and player.is_on_floor()
	if not player.held("skill"):
		_hook = null
	if player.pressed("skill") and not player.is_on_floor():
		_hook = _find_hook()
	if is_instance_valid(_hook):
		var d := _hook.global_position - player.global_position
		player.velocity = d.normalized() * minf(420, d.length() * 12)
		if d.length() < 16 or player.is_on_wall():
			_hook = null
	if _rope:
		var mate := player.teammate()
		if mate and mate.alive and not mate.carried_by and mate.held("jump") and not mate.held("left") and not mate.held("right") and not mate.held("skill") and absf(mate.global_position.x - rope_x()) < 26 and mate.global_position.y > player.global_position.y - 44 and mate.global_position.y < player.global_position.y + rope_length:
			mate.rope_provider = player
	tick_attack(delta)
	queue_redraw()

func rope_active() -> bool:
	return _rope and player.carried_by == null and player.held("skill") and player.is_on_floor()

func rope_x() -> float:
	return player.global_position.x + player.facing * 36.0

func is_driving() -> bool:
	if _rope: player.velocity = Vector2(0, 30)  # Keep the floor contact valid while anchoring.
	return _rope or is_instance_valid(_hook)

func tick_attack(delta: float) -> void:
	queue_redraw()
	_lasso_time = maxf(0, _lasso_time - delta)
	_cooldown = maxf(0, _cooldown - delta)
	if not player.pressed("attack") or _cooldown > 0: return
	_cooldown = 0.55
	var target: Node2D = null
	var best := lasso_reach
	for enemy in player.get_tree().get_nodes_in_group("enemies") + player.get_tree().get_nodes_in_group("levers"):
		if not (enemy is ClipperBot or enemy is Lever): continue
		var aim: Vector2 = enemy.global_position + (Vector2(0, -12) if enemy is ClipperBot else Vector2.ZERO)
		var d: Vector2 = aim - player.global_position
		if d.x * player.facing < 0 or d.length() > best or not _clear_path(aim): continue
		target = enemy
		best = d.length()
	_lasso_end = player.global_position + Vector2(player.facing * lasso_reach, -20)
	_lasso_time = 0.22
	if target:
		_lasso_end = target.global_position
		if target is Lever:
			target.interact(player)
		else:
			target.take_hit(0, 1.0, (player.global_position - target.global_position).normalized() * 460)

func tick_carried(delta: float) -> void:
	_rope = false
	_hook = null
	tick_attack(delta)

func _find_hook() -> Node2D:
	var best: Node2D = null
	var distance := hook_reach
	for ring: Node2D in player.get_tree().get_nodes_in_group("hair_anchors"):
		var d := ring.global_position.distance_to(player.global_position)
		if d < distance and _clear_path(ring.global_position):
			best = ring
			distance = d
	return best

func _clear_path(to: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(player.global_position + Vector2(0, -10), to, Layers.WORLD)
	return player.get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func anim() -> StringName:
	if _lasso_time > 0: return &"lasso"
	if _rope or is_instance_valid(_hook): return &"rope"
	return &""

func reset() -> void:
	_rope = false
	_hook = null
	_lasso_time = 0
	_cooldown = 0

func _draw() -> void:
	if _rope:
		draw_line(Vector2(0, -26), Vector2(36, -26), Color("2b2140"), 9, true)
		draw_line(Vector2(36, -26), Vector2(36, rope_length), Color("2b2140"), 9, true)
		draw_line(Vector2(36, -26), Vector2(36, rope_length), HAIR_COLOR, 5, true)
		for y in range(0, int(rope_length), 24):
			draw_line(Vector2(30, y), Vector2(42, y), Color("d9c4f2"), 3, true)
	if is_instance_valid(_hook):
		draw_line(Vector2(0, -20), to_local(_hook.global_position), HAIR_COLOR, 5, true)
	if _lasso_time > 0:
		var end := to_local(_lasso_end)
		draw_line(Vector2(0, -20), end, HAIR_COLOR, 4, true)
		draw_arc(end, 16, 0, TAU, 20, HAIR_COLOR, 3, true)
