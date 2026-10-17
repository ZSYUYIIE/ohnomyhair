class_name Player
extends CharacterBody2D
## Shared controller for both players (PLAN.md 2.5). The hairstyle lives in `ability`.
## Origin is at the feet.

const BODY_SIZE := Vector2(12, 22)
const HEAD_TOP := -24.0          # where a teammate's feet rest when standing on this head

@export var player_id := 1
@export var color := Color.WHITE
@export var run_speed := 140.0
@export var jump_height := 56.0
@export var time_to_apex := 0.35
@export var fall_multiplier := 1.8
@export var coyote_time := 0.1
@export var jump_buffer := 0.12
@export var max_hp := 3
@export var invincible_time := 0.7

var ability: HairAbility
var gravity: float
var jump_velocity: float
var hp := 3
var facing := 1.0
var max_fall_speed := INF
var launched := false            # set by a launch; ignores the short-hop cut until the apex
var control_lock := 0.0          # seconds where input doesn't set velocity.x (knockback, dash)
var hit_box: Area2D

var _coyote := 0.0
var _buffer := 0.0
var _invincible := 0.0
var _hit_shape: CollisionShape2D


func _ready() -> void:
	add_to_group("players")
	gravity = 2.0 * jump_height / pow(time_to_apex, 2)
	jump_velocity = -2.0 * jump_height / time_to_apex
	hp = max_hp
	collision_layer = Layers.PLAYERS
	collision_mask = Layers.WORLD | Layers.HEAD_PADS
	_add_rect_shape(self, BODY_SIZE, Vector2(0, -BODY_SIZE.y / 2))

	# One-way pad on the head so the teammate can stand here but still walk through us.
	var head_pad := AnimatableBody2D.new()
	head_pad.sync_to_physics = false   # follow the parent's moves, not only local ones
	head_pad.collision_layer = Layers.HEAD_PADS
	head_pad.collision_mask = 0
	_add_rect_shape(head_pad, Vector2(14, 2), Vector2(0, HEAD_TOP + 1)).one_way_collision = true
	add_child(head_pad)
	add_collision_exception_with(head_pad)

	hit_box = Area2D.new()
	hit_box.collision_layer = 0
	hit_box.collision_mask = Layers.ENEMIES | Layers.ENEMY_ATTACK
	_hit_shape = _add_rect_shape(hit_box, Vector2(22, 26), Vector2(12, -12))
	add_child(hit_box)

	if ability:
		add_child(ability)
		ability.setup(self)


func act(action: String) -> StringName:
	return StringName("p%d_%s" % [player_id, action])


func teammate() -> Player:
	for p in get_tree().get_nodes_in_group("players"):
		if p != self:
			return p
	return null


func _physics_process(delta: float) -> void:
	_invincible = maxf(_invincible - delta, 0.0)
	control_lock = maxf(control_lock - delta, 0.0)

	_coyote = coyote_time if is_on_floor() else _coyote - delta
	_buffer -= delta
	if Input.is_action_just_pressed(act("jump")):
		_buffer = jump_buffer
	if _buffer > 0.0 and _coyote > 0.0:
		velocity.y = jump_velocity
		_buffer = 0.0
		_coyote = 0.0
	if Input.is_action_just_released(act("jump")) and velocity.y < 0.0 and not launched:
		velocity.y *= 0.45             # short press = small hop
	if launched and velocity.y >= 0.0:
		launched = false

	velocity.y += gravity * (fall_multiplier if velocity.y > 0.0 else 1.0) * delta
	var axis := Input.get_axis(act("left"), act("right"))
	if control_lock > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	else:
		velocity.x = axis * run_speed
		if axis != 0.0:
			facing = signf(axis)

	max_fall_speed = INF
	if ability:
		ability.tick(delta)
	velocity.y = minf(velocity.y, max_fall_speed)
	_hit_shape.position.x = 12.0 * facing
	move_and_slide()

	modulate.a = 0.35 if _invincible > 0.0 and int(_invincible * 20.0) % 2 == 0 else 1.0
	queue_redraw()


func take_hit(damage: int, _stun_time: float = 0.0, knockback := Vector2.ZERO) -> void:
	if damage <= 0 or _invincible > 0.0:
		return
	hp -= damage
	_invincible = invincible_time
	if knockback != Vector2.ZERO:
		velocity = knockback
		control_lock = 0.2
	if hp <= 0:
		Game.respawn.call_deferred()


func respawn(at: Vector2) -> void:
	global_position = at
	velocity = Vector2.ZERO
	hp = max_hp
	launched = false
	_invincible = 1.0


func _draw() -> void:
	draw_rect(Rect2(Vector2(-BODY_SIZE.x / 2, -BODY_SIZE.y), BODY_SIZE), color)
	draw_rect(Rect2(Vector2(2.0 * facing - 1.0, -18), Vector2(2, 3)), Color.BLACK)
	if ability:
		ability.draw_hair(self)


static func _add_rect_shape(owner_node: Node, size: Vector2, offset: Vector2) -> CollisionShape2D:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = offset
	owner_node.add_child(shape)
	return shape
