class_name BarberBot
extends CharacterBody2D
## L3 boss: the runaway barber robot. Origin is at the feet.
## Loop: WALK toward a player -> SHOOT 3 scissors / WINDUP + CHARGE (alternating).
## It only takes damage from being stomped on its head knob while DAZED. It gets dazed by
## a parried scissor (3 s) or by crashing into a wall at the end of a charge (shorter).
## Whips, dashes and parry swings just bounce off ("too big").
## Each state is a function that returns the next state, or `stay` to remain.

signal defeated

enum State { WALK, SHOOT, WINDUP, CHARGE, DAZED, HURT, DEAD }

const SIZE := Vector2(96, 128)
## Charging, it ducks its head like a bull: only this much of it is solid, so a full
## jump (about 114 px) clears it. Standing tall it can't be jumped (128 px).
const CHARGE_HEIGHT := 72.0
const KNOB_HEIGHT := 40.0  # stomp zone on top of the head

@export var hp := 3
@export var walk_speed := 90.0
@export var walk_time := 1.6
## While walking it keeps about this far from the nearest player (so its scissors
## come from far enough away to read and parry), backing off if they get closer.
@export var keep_distance := 192.0
@export var shots := 3
@export var shot_gap := 0.5
@export var windup_time := 0.7
@export var charge_speed := 560.0
@export var charge_timeout := 3.0
@export var crash_daze_time := 2.0
## Long enough to carry your friend over on your head and launch them onto the knob.
@export var parry_daze_time := 4.0
@export var hurt_time := 0.8

var state := State.WALK
var facing := -1.0
var _t := 0.0
var _shots_left := 0
var _charge_next := false
var _knob: Area2D
var _flash := 0.0


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = Layers.ENEMIES
	collision_mask = Layers.WORLD
	Player.add_rect_shape(self, SIZE, Vector2(0, -SIZE.y / 2))
	_knob = Area2D.new()
	_knob.collision_layer = 0
	_knob.collision_mask = Layers.PLAYERS
	_knob.monitorable = false
	Player.add_rect_shape(_knob, Vector2(SIZE.x - 8, KNOB_HEIGHT), Vector2(0, -SIZE.y))
	add_child(_knob)
	_enter(State.WALK)


func _physics_process(delta: float) -> void:
	velocity.y += 1800.0 * delta
	_flash = maxf(_flash - delta, 0.0)
	_t -= delta
	var next: State = state
	match state:
		State.WALK: next = _walk()
		State.SHOOT: next = _shoot()
		State.WINDUP: next = _windup()
		State.CHARGE: next = _charge()
		State.DAZED: next = _dazed()
		State.HURT: next = _hurt()
		State.DEAD: velocity.x = 0.0
	move_and_slide()
	if next != state:
		_enter(next)
	queue_redraw()


func _enter(new_state: State) -> void:
	state = new_state
	match state:
		State.WALK:
			_t = walk_time
		State.SHOOT:
			_shots_left = shots
			_t = 0.3
		State.WINDUP:
			_t = windup_time
			_face_target()
		State.CHARGE:
			_t = charge_timeout
		State.HURT:
			_t = hurt_time


# --- States -------------------------------------------------------------------

func _walk() -> State:
	_face_target()
	var target := _nearest_player()
	var gap := absf(target.global_position.x - global_position.x) if target else keep_distance
	if gap > keep_distance + 32.0:
		velocity.x = facing * walk_speed
	elif gap < keep_distance - 32.0:
		velocity.x = -facing * walk_speed
	else:
		velocity.x = 0.0
	_hurt_touching_players()
	if _t > 0.0:
		return State.WALK
	_charge_next = not _charge_next
	return State.WINDUP if _charge_next else State.SHOOT


func _shoot() -> State:
	velocity.x = 0.0
	_face_target()
	if _t <= 0.0 and _shots_left > 0:
		_fire()
		_shots_left -= 1
		_t = shot_gap
	if _shots_left == 0 and _t <= 0.0:
		return State.WALK
	return State.SHOOT


func _windup() -> State:
	velocity.x = 0.0
	_flash = 0.1
	return State.CHARGE if _t <= 0.0 else State.WINDUP


func _charge() -> State:
	velocity.x = facing * charge_speed
	_hurt_touching_players()
	if is_on_wall():
		daze(crash_daze_time)
		return State.DAZED
	return State.WALK if _t <= 0.0 else State.CHARGE


func _dazed() -> State:
	velocity.x = 0.0
	for body in _knob.get_overlapping_bodies():
		if body is Player and body.alive and body.velocity.y > 0.0:
			_stomped_by(body)
			return State.DEAD if hp <= 0 else State.HURT
	return State.WALK if _t <= 0.0 else State.DAZED


func _hurt() -> State:
	velocity.x = 0.0
	_flash = 0.1
	return State.WALK if _t <= 0.0 else State.HURT


# --- Interactions -------------------------------------------------------------

func daze(seconds: float) -> void:
	if state == State.DEAD or state == State.HURT:
		return
	state = State.DAZED
	_t = seconds


## Only a parried scissor (stun 3 s) is strong enough to daze it.
func take_hit(_damage: int, stun_time: float = 0.0, _knockback := Vector2.ZERO) -> void:
	if stun_time >= 2.0:
		daze(maxf(parry_daze_time, stun_time))  # a golden (hair-caught) scissor dazes longer


func _stomped_by(player: Player) -> void:
	hp -= 1
	player.launch(96.0)
	player.make_invincible(1.2)
	player.hit_stop(0.08)
	if hp <= 0:
		collision_layer = 0
		defeated.emit()
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.8)
		tween.tween_callback(queue_free)


func _fire() -> void:
	var scissor := Scissor.new()
	scissor.direction = Vector2(facing, 0)
	# Body height of a player standing on the same floor, so it's parriable and dodgeable by jumping.
	scissor.position = position + Vector2(facing * (SIZE.x / 2 + 16), -30)
	get_parent().add_child.call_deferred(scissor)


func _face_target() -> void:
	var target := _nearest_player()
	if target and absf(target.global_position.x - global_position.x) > 4.0:
		facing = signf(target.global_position.x - global_position.x)


func _nearest_player() -> Player:
	var best: Player = null
	for p: Player in get_tree().get_nodes_in_group("players"):
		if p.alive and (best == null or absf(p.global_position.x - global_position.x) < absf(best.global_position.x - global_position.x)):
			best = p
	return best


func _hurt_touching_players() -> void:
	var h := CHARGE_HEIGHT if state == State.CHARGE else SIZE.y
	var me := Rect2(global_position + Vector2(-SIZE.x / 2, -h), Vector2(SIZE.x, h))
	for p: Player in get_tree().get_nodes_in_group("players"):
		var them := Rect2(p.global_position - Player.HALF_SIZE, Player.HALF_SIZE * 2.0)
		if p.alive and me.intersects(them):
			p.take_hit(1, 0.0, Vector2(signf(p.global_position.x - global_position.x) * 360.0, -300.0))


func _draw() -> void:
	if state == State.CHARGE:
		# Head down, squashed low: reads as "jump over me".
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.15, CHARGE_HEIGHT / SIZE.y))
	var body := Color("c0392b")
	match state:
		State.DAZED: body = Color("7f8c8d")
		State.HURT, State.WINDUP: body = Color.WHITE if int(_flash * 40.0) % 2 == 0 else Color("e74c3c")
	var top := -SIZE.y
	draw_rect(Rect2(-SIZE.x / 2, top + 24, SIZE.x, SIZE.y - 24), body)
	draw_rect(Rect2(-SIZE.x / 2 + 8, top + 8, SIZE.x - 16, 20), Color("2c3e50"))    # head
	draw_rect(Rect2(facing * 20 - 8, top + 12, 16, 10), Color("f1c40f"))            # eye
	# Scissor arms
	var arm := Vector2(facing * (SIZE.x / 2 + 18), top + 70)
	draw_line(Vector2(facing * SIZE.x / 2, top + 64), arm + Vector2(0, -10), Color("bdc3c7"), 6.0)
	draw_line(Vector2(facing * SIZE.x / 2, top + 76), arm + Vector2(0, 10), Color("bdc3c7"), 6.0)
	# Head knob: the weak point, glowing while dazed
	var knob := Color("f1c40f") if state == State.DAZED else Color("7f8c8d")
	draw_rect(Rect2(-18, top - 4, 36, 12), knob)
	if state == State.DAZED:
		draw_string(ThemeDB.fallback_font, Vector2(-44, top - 14), "STOMP!", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f1c40f"))
	for i in hp:
		draw_rect(Rect2(-SIZE.x / 2 + i * 34, top - 34 if state != State.DAZED else top - 44, 28, 6), Color("e74c3c"))
