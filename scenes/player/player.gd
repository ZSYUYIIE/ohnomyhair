class_name Player
extends CharacterBody2D
## Shared controller for both friends. Movement, HP and carrying live here; whatever
## the haircut does lives in a HairAbility child, so hair can be swapped at runtime.
## Origin is the body's center. Friends pass through each other, but each has a
## one-way pad on top of the head so the other can stand on it (for the launch).

signal died(player: Player)

enum Hair { TWIN_TAILS, POMPADOUR }

const HAIR_SCRIPTS := {
	Hair.TWIN_TAILS: preload("res://scenes/player/abilities/twin_tails.gd"),
	Hair.POMPADOUR: preload("res://scenes/player/abilities/pompadour.gd"),
}
const HALF_SIZE := Vector2(14, 22)  # keep in sync with CollisionShape2D (28x44)
## Carried friend is drawn this far below the carrier. Visual only: their collision
## box sits exactly on the carrier's, so they can never snag on a ledge the carrier clears.
const CARRY_HANG := Vector2(0, 30)

@export var player_id := 1
@export var hair := Hair.TWIN_TAILS

@export_group("Movement")
@export var run_speed := 280.0
@export var ground_accel := 4000.0
@export var air_accel := 2600.0
@export var jump_height := 120.0  # 3.75 tiles
@export var time_to_apex := 0.35
@export var fall_multiplier := 1.8
@export var max_fall_speed := 900.0
@export var coyote_time := 0.1
@export var jump_buffer := 0.12
@export var jump_cut := 0.45

@export_group("Health")
@export var max_hp := 3
@export var invincible_time := 0.7

@onready var gravity := 2.0 * jump_height / (time_to_apex * time_to_apex)
@onready var jump_velocity := -2.0 * jump_height / time_to_apex
@onready var visual: Node2D = $Visual
@onready var body_rect: ColorRect = $Visual/Body
@onready var interact_area: Area2D = $InteractArea
@onready var head_pad: AnimatableBody2D = $HeadPad
@onready var hit_box: Area2D = $HitBox
@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var label: Label = $Label
@onready var _label_home := label.position

var ability: HairAbility
var facing := 1.0
var alive := true
var hp := 3
## Abilities lower this each tick (gliding); reset to max_fall_speed every frame.
var fall_cap := 0.0
## Seconds during which input doesn't steer (knockback).
var control_lock := 0.0
var carrying: Player = null
var carried_by: Player = null

var _actions := {}
var _coyote := 0.0
var _buffer := 0.0
var _can_cut_jump := false
var _invincible := 0.0
var _drop_through := 0.0
var _separating: Player = null  # pads are re-enabled once we no longer overlap this friend


func _ready() -> void:
	for a in ["left", "right", "jump", "down", "skill", "attack"]:
		_actions[a] = StringName("p%d_%s" % [player_id, a])
	add_to_group("players")
	add_collision_exception_with(head_pad)
	label.text = "P%d" % player_id
	hp = max_hp
	set_hair(hair)


func act(action: String) -> StringName:
	return _actions[action]


func pressed(action: String) -> bool:
	return Input.is_action_just_pressed(_actions[action])


func held(action: String) -> bool:
	return Input.is_action_pressed(_actions[action])


func released(action: String) -> bool:
	return Input.is_action_just_released(_actions[action])


func teammate() -> Player:
	for p in get_tree().get_nodes_in_group("players"):
		if p != self:
			return p
	return null


func set_hair(new_hair: Hair) -> void:
	hair = new_hair
	if ability:
		ability.reset()
		ability.queue_free()
	ability = HAIR_SCRIPTS[hair].new()
	ability.player = self
	visual.add_child(ability)
	body_rect.color = ability.body_color


func _physics_process(delta: float) -> void:
	if _separating and _apart_from(_separating):
		_set_pads_with(_separating, true)
		_separating = null
	_invincible = maxf(_invincible - delta, 0.0)
	visual.modulate.a = 0.35 if _invincible > 0.0 and int(_invincible * 20.0) % 2 == 0 else 1.0
	if not alive:
		return
	if carried_by:
		_follow_carrier()
		hit_box.position.x = absf(hit_box.position.x) * facing
		ability.tick_carried(delta)
		return
	_ease_visual_to(Vector2.ZERO)

	_coyote = coyote_time if is_on_floor() else _coyote - delta
	_buffer = jump_buffer if pressed("jump") else _buffer - delta
	control_lock = maxf(control_lock - delta, 0.0)

	var dir := Input.get_axis(_actions.left, _actions.right)
	if dir != 0.0 and control_lock <= 0.0:
		facing = signf(dir)
		visual.scale.x = facing
	hit_box.position.x = absf(hit_box.position.x) * facing

	fall_cap = max_fall_speed
	ability.tick(delta)
	if ability.is_driving():
		move_and_slide()
		ability.after_move()
		return

	# Hold down to drop through one-way platforms: stop colliding with their layer for a moment.
	if held("down") and is_on_floor():
		_drop_through = 0.25
	_drop_through = maxf(_drop_through - delta, 0.0)
	set_collision_mask_value(8, _drop_through <= 0.0)  # layer 8 = Layers.PLATFORMS
	if _buffer > 0.0 and _coyote > 0.0:
		# Carrying always takes a full jump: a short hop with a friend attached just drops them in the dye.
		_jump(jump_velocity, carrying == null)
	if released("jump") and _can_cut_jump and velocity.y < 0.0:
		velocity.y *= jump_cut
		_can_cut_jump = false

	var g := gravity * (fall_multiplier if velocity.y > 0.0 else 1.0)
	velocity.y += g * delta
	if velocity.y > fall_cap:
		velocity.y = move_toward(velocity.y, fall_cap, 4000.0 * delta)
	if control_lock > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)
	else:
		var accel := ground_accel if is_on_floor() else air_accel
		velocity.x = move_toward(velocity.x, dir * run_speed, accel * delta)

	move_and_slide()
	ability.after_move()


func _jump(v: float, can_cut: bool) -> void:
	velocity.y = v
	_buffer = 0.0
	_coyote = 0.0
	_can_cut_jump = can_cut


## Thrown upward by a friend; rises `height` pixels and can't be cut short.
func launch(height: float) -> void:
	_jump(-sqrt(2.0 * gravity * height), false)


## True when `other` is standing on this player's head pad.
func has_rider(other: Player) -> bool:
	var feet := other.global_position.y + HALF_SIZE.y
	var head := global_position.y - HALF_SIZE.y
	return other.is_on_floor() and absf(feet - head) < 6.0 and absf(other.global_position.x - global_position.x) < HALF_SIZE.x * 2.0


# --- Damage -------------------------------------------------------------------

func take_hit(damage: int, _stun_time: float = 0.0, knockback := Vector2.ZERO) -> void:
	if damage <= 0 or _invincible > 0.0 or not alive:
		return
	hp -= damage
	_invincible = invincible_time
	if knockback != Vector2.ZERO and carried_by == null:
		velocity = knockback
		control_lock = 0.2
	if hp <= 0:
		die()


func make_invincible(seconds: float) -> void:
	_invincible = maxf(_invincible, seconds)


# --- Carrying (twin-tails grab) ---------------------------------------------

func grab(other: Player) -> void:
	carrying = other
	other.carried_by = self
	other.velocity = Vector2.ZERO
	_set_pads_with(other, false)


func drop() -> void:
	if carrying == null:
		return
	var other := carrying
	carrying = null
	other.carried_by = null
	_separating = other


## While carried: ride exactly on the carrier. Jump is ignored on purpose (players
## mash it in sync with the carrier's jump); press down to let go.
func _follow_carrier() -> void:
	var carrier := carried_by
	if pressed("down"):
		carrier.drop()
		return
	global_position = carrier.global_position
	velocity = carrier.velocity
	facing = carrier.facing
	visual.scale.x = facing
	# Dangle below in the air; tuck in behind the carrier when they stand on the ground.
	_ease_visual_to(CARRY_HANG if not carrier.is_on_floor() else Vector2(-carrier.facing * 16.0, 0))


func _ease_visual_to(offset: Vector2) -> void:
	if visual.position == offset:
		return
	visual.position = visual.position.lerp(offset, 0.3)
	if visual.position.distance_to(offset) < 0.5:
		visual.position = offset
	label.position = _label_home + visual.position


## Overlapping friends must not stand on each other's head pads.
func _set_pads_with(other: Player, on: bool) -> void:
	if on:
		remove_collision_exception_with(other.head_pad)
		other.remove_collision_exception_with(head_pad)
	else:
		add_collision_exception_with(other.head_pad)
		other.add_collision_exception_with(head_pad)


func _apart_from(other: Player) -> bool:
	var d := (other.global_position - global_position).abs()
	return d.x > HALF_SIZE.x * 2.0 + 2.0 or d.y > HALF_SIZE.y * 2.0 + 2.0


# --- Death / respawn ----------------------------------------------------------

func die() -> void:
	if not alive:
		return
	alive = false
	drop()
	if carried_by:
		carried_by.drop()
	hide()
	shape.set_deferred("disabled", true)
	died.emit(self)


func respawn_at(pos: Vector2) -> void:
	drop()
	if carried_by:
		carried_by.drop()
	for p in get_tree().get_nodes_in_group("players"):
		if p != self:
			_set_pads_with(p, true)
	_separating = null
	global_position = pos
	velocity = Vector2.ZERO
	visual.position = Vector2.ZERO
	label.position = _label_home
	_coyote = 0.0
	_buffer = 0.0
	control_lock = 0.0
	hp = max_hp
	_invincible = 1.0
	ability.reset()
	alive = true
	show()
	shape.set_deferred("disabled", false)


func set_frozen(frozen: bool) -> void:
	set_physics_process(not frozen)
	if frozen:
		velocity = Vector2.ZERO


## Freeze-frame for impact (parry, volley, boss hits).
func hit_stop(duration: float) -> void:
	freeze_frame(get_tree(), duration)


## Restoring the time scale must not depend on the caller surviving the freeze: if it
## awaited the timer itself, freeing it mid-freeze (room change, test arena) would leave
## the whole game stuck at 5% speed. A lambda made in a static func isn't bound to anyone.
static func freeze_frame(tree: SceneTree, duration: float) -> void:
	Engine.time_scale = 0.05
	tree.create_timer(duration, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)


## Adds a rectangle CollisionShape2D (centered at `offset`) to a physics node built in code.
static func add_rect_shape(owner_node: Node, size: Vector2, offset: Vector2) -> CollisionShape2D:
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	col.shape = rect
	col.position = offset
	owner_node.add_child(col)
	return col
