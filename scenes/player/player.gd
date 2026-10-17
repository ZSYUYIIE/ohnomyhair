class_name Player
extends CharacterBody2D
## Shared controller for both friends. Movement lives here; whatever the
## haircut does lives in a HairAbility child, so hair can be swapped at runtime.

signal died(player: Player)

enum Hair { TWIN_TAILS, POMPADOUR }

const HAIR_SCRIPTS := {
	Hair.TWIN_TAILS: preload("res://scenes/player/abilities/twin_tails.gd"),
	Hair.POMPADOUR: preload("res://scenes/player/abilities/pompadour.gd"),
}
const HALF_SIZE := Vector2(14, 22)  # keep in sync with CollisionShape2D (28x44)
const CARRY_OFFSET := Vector2(0, 48)  # carried friend hangs this far below the carrier
const CARRY_BREAK_DISTANCE := 96.0

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

@onready var gravity := 2.0 * jump_height / (time_to_apex * time_to_apex)
@onready var jump_velocity := -2.0 * jump_height / time_to_apex
@onready var visual: Node2D = $Visual
@onready var body_rect: ColorRect = $Visual/Body
@onready var interact_area: Area2D = $InteractArea
@onready var head_pad: Area2D = $HeadPad
@onready var shape: CollisionShape2D = $CollisionShape2D

var ability: HairAbility
var facing := 1.0
var alive := true
## Abilities lower this each tick (gliding); reset to max_fall_speed every frame.
var fall_cap := 0.0
var carrying: Player = null
var carried_by: Player = null

var _actions := {}
var _coyote := 0.0
var _buffer := 0.0
var _can_cut_jump := false
var _separating: Player = null  # collision with this friend is restored once we no longer overlap


func _ready() -> void:
	for a in ["left", "right", "jump", "down", "skill", "attack"]:
		_actions[a] = StringName("p%d_%s" % [player_id, a])
	add_to_group("players")
	$Label.text = "P%d" % player_id
	set_hair(hair)


func pressed(action: String) -> bool:
	return Input.is_action_just_pressed(_actions[action])


func held(action: String) -> bool:
	return Input.is_action_pressed(_actions[action])


func released(action: String) -> bool:
	return Input.is_action_just_released(_actions[action])


func set_hair(new_hair: Hair) -> void:
	hair = new_hair
	if ability:
		ability.queue_free()
	ability = HAIR_SCRIPTS[hair].new()
	ability.player = self
	visual.add_child(ability)
	body_rect.color = ability.body_color


func _physics_process(delta: float) -> void:
	if _separating and _apart_from(_separating):
		_set_collision_with(_separating, true)
		_separating = null
	if not alive:
		return
	if carried_by:
		_follow_carrier(delta)
		return

	_coyote = coyote_time if is_on_floor() else _coyote - delta
	_buffer = jump_buffer if pressed("jump") else _buffer - delta

	var dir := Input.get_axis(_actions.left, _actions.right)
	if dir != 0.0:
		facing = signf(dir)
		visual.scale.x = facing

	fall_cap = max_fall_speed
	ability.tick(delta)
	if ability.is_driving():
		move_and_slide()
		ability.after_move()
		return

	if _buffer > 0.0 and _coyote > 0.0:
		_jump(jump_velocity, true)
	if released("jump") and _can_cut_jump and velocity.y < 0.0:
		velocity.y *= jump_cut
		_can_cut_jump = false

	var g := gravity * (fall_multiplier if velocity.y > 0.0 else 1.0)
	velocity.y += g * delta
	if velocity.y > fall_cap:
		velocity.y = move_toward(velocity.y, fall_cap, 4000.0 * delta)
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


# --- Carrying (twin-tails grab) ---------------------------------------------

func grab(other: Player) -> void:
	carrying = other
	other.carried_by = self
	other.velocity = Vector2.ZERO
	_set_collision_with(other, false)


func drop() -> void:
	if carrying == null:
		return
	var other := carrying
	carrying = null
	other.carried_by = null
	_separating = other


func _follow_carrier(delta: float) -> void:
	var carrier := carried_by
	if pressed("jump"):
		carrier.drop()
		_jump(jump_velocity * 0.7, false)
		return
	var to_anchor := carrier.global_position + CARRY_OFFSET - global_position
	if to_anchor.length() > CARRY_BREAK_DISTANCE:
		carrier.drop()
		return
	# Steer onto the anchor with move_and_slide so the dangling friend still collides with walls.
	velocity = (to_anchor / delta).limit_length(1500.0)
	facing = carrier.facing
	visual.scale.x = facing
	move_and_slide()


func _set_collision_with(other: Player, on: bool) -> void:
	if on:
		remove_collision_exception_with(other)
		other.remove_collision_exception_with(self)
	else:
		add_collision_exception_with(other)
		other.add_collision_exception_with(self)


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
			_set_collision_with(p, true)
	_separating = null
	global_position = pos
	velocity = Vector2.ZERO
	_coyote = 0.0
	_buffer = 0.0
	ability.reset()
	alive = true
	show()
	shape.set_deferred("disabled", false)


func set_frozen(frozen: bool) -> void:
	set_physics_process(not frozen)
	if frozen:
		velocity = Vector2.ZERO
