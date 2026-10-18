class_name BarberBot
extends CharacterBody2D
## L6 (finale) boss: the runaway barber robot. Origin is at the feet.
## Loop: approach -> charge / aimed burst / marked overhead snips.
## Ten health: phase 2 at 6, phase 3 at 3. Phase changes notify the arena controller.
##   1 - base attacks; 2 - showers/roaming backup; 3 - faster attacks and more backup.
## It only takes damage from being stomped on its head knob while DAZED. It gets dazed by
## a parried scissor (3 s) or by crashing into a wall at the end of a charge (shorter).
## Whips, dashes and parry swings just bounce off ("too big").
## Each state is a function that returns the next state, or `stay` to remain.

signal defeated
signal backup_called
signal phase_changed(number: int)

enum State { WALK, SHOOT, WINDUP, CHARGE, RAIN, DAZED, HURT, DEAD }

const SIZE := Vector2(96, 128)
## The charge's damaging core is lower so a full jump (about 114 px) clears it.
## The upright running drawing keeps the same height; the jump window stays forgiving.
const CHARGE_HEIGHT := 72.0
const KNOB_HEIGHT := 40.0  # stomp zone on top of the head

@export var hp := 10
@export var walk_speed := 90.0
@export var walk_time := 1.6
## Stop approaching within this distance, keeping scissors readable without backsliding.
@export var keep_distance := 192.0
@export var shots := 3
@export var shot_gap := 0.5
## Every shot warns first, then stops tracking before release. No homing in flight.
const AIM_LOCK := 0.20
const AIM_WARNING := 0.65
const ACCELERATION := 600.0
const CHARGE_ACCELERATION := 2400.0
const Rain := preload("res://scenes/enemies/boss_scissor_rain.gd")
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
var _attack_index := 0
var _aim_target: Player
var _aim_point := Vector2.ZERO
var _aim_locked := false
var _knob: Area2D
var _max_hp := 10
var _bar: BossBar
var _animation_time := 0.0
var _pose_age := 0.0
var _last_pose := -1
var _gait_distance := 0.0


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
	_max_hp = hp
	_enter(State.WALK)


func _physics_process(delta: float) -> void:
	_animation_time += delta
	_pose_age = _pose_age + delta if state == _last_pose else 0.0
	_last_pose = state
	if _bar == null:
		# Made on the first tick, which only comes once its room is the current one.
		_bar = BossBar.new(self)
		add_child(_bar)
	velocity.y += 1800.0 * delta
	_t -= delta
	var next: State = state
	match state:
		State.WALK: next = _walk(delta)
		State.SHOOT: next = _shoot()
		State.WINDUP: next = _windup()
		State.CHARGE: next = _charge(delta)
		State.RAIN: next = State.WALK if _t <= 0.0 else State.RAIN
		State.DAZED: next = _dazed()
		State.HURT: next = _hurt()
		State.DEAD: velocity.x = 0.0
	var before := position.x
	move_and_slide()
	if state in [State.WALK, State.CHARGE] and is_on_floor():
		_gait_distance += absf(position.x - before)
	if next != state:
		_enter(next)
	queue_redraw()


func _enter(new_state: State) -> void:
	state = new_state
	_pose_age = 0.0
	if state != State.WALK and state != State.CHARGE:
		velocity.x = 0.0
	match state:
		State.WALK:
			_t = walk_time
		State.SHOOT:
			_shots_left = shots
			_prepare_aim()
		State.WINDUP:
			_t = windup_time
			_face_target()
		State.CHARGE:
			Sound.play("boss_charge", 0.0)
			_t = charge_timeout
		State.HURT:
			_t = hurt_time
		State.RAIN:
			_t = 1.5
			_call_overhead_snips()


# --- States -------------------------------------------------------------------

func _walk(delta: float) -> State:
	_face_target()
	var target := _nearest_player()
	var gap := absf(target.global_position.x - global_position.x) if target else keep_distance
	var desired := facing * walk_speed if gap > keep_distance + 32.0 else 0.0
	velocity.x = move_toward(velocity.x, desired, ACCELERATION * delta)
	_hurt_touching_players()
	if _t > 0.0:
		return State.WALK
	var attack: State = [State.WINDUP, State.SHOOT, State.RAIN][_attack_index % 3]
	_attack_index += 1
	return attack


func _shoot() -> State:
	velocity.x = 0.0
	if not _aim_locked and _t <= AIM_LOCK:
		_aim_locked = true
	elif not _aim_locked and is_instance_valid(_aim_target) and _aim_target.alive:
		_aim_point = _aim_target.global_position
		if absf(_aim_point.x - global_position.x) > 4:
			facing = signf(_aim_point.x - global_position.x)
	if _t <= 0.0 and _shots_left > 0:
		_fire()
		_shots_left -= 1
		if _shots_left > 0:
			_prepare_aim()
		else:
			_t = 0.35
	if _shots_left == 0 and _t <= 0.0:
		return State.WALK
	return State.SHOOT


func _windup() -> State:
	velocity.x = 0.0
	return State.CHARGE if _t <= 0.0 else State.WINDUP


func _charge(delta: float) -> State:
	velocity.x = move_toward(velocity.x, facing * charge_speed, CHARGE_ACCELERATION * delta)
	_hurt_touching_players()
	if is_on_wall():
		daze(crash_daze_time)
		Sound.play("boss_stomp", 0.05, -4.0)  # the crash into the wall
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
	return State.WALK if _t <= 0.0 else State.HURT


# --- Interactions -------------------------------------------------------------

func daze(seconds: float) -> void:
	if state == State.DEAD or state == State.HURT:
		return
	if state != State.DAZED:
		Sound.play("boss_daze")
	state = State.DAZED
	_t = seconds
	velocity.x = 0.0


## Only a parried scissor (stun 3 s) is strong enough to daze it.
func take_hit(_damage: int, stun_time: float = 0.0, _knockback := Vector2.ZERO) -> void:
	if stun_time >= 2.0:
		daze(maxf(parry_daze_time, stun_time))  # a golden (hair-caught) scissor dazes longer


func _stomped_by(player: Player) -> void:
	Sound.play("boss_stomp", 0.0)
	var previous_phase := phase()
	hp -= 1
	player.launch(96.0)
	player.make_invincible(1.2)
	player.hit_stop(0.08)
	if hp <= 0:
		collision_layer = 0
		Level.banner_for(self, "The assistant is down!", 2.0)
		defeated.emit()
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.8)
		tween.tween_callback(queue_free)
	elif phase() != previous_phase:
		if phase() == 2:
			Level.banner_for(self, "PHASE 2: showers + backup!", 1.8)
			backup_called.emit()
		else:
			_enrage()
		phase_changed.emit(phase())


## The last 30% of health: furious, with additional arena pressure.
func _enrage() -> void:
	Level.banner_for(self, "PHASE 3: it's furious!", 1.8)
	walk_speed *= 1.35
	charge_speed *= 1.2
	windup_time = 0.5
	shots = 5
	shot_gap = 0.40


func phase() -> int:
	if hp <= maxi(1, roundi(_max_hp * 0.3)): return 3
	if hp <= maxi(2, roundi(_max_hp * 0.6)): return 2
	return 1


func _fire() -> void:
	var scissor := Scissor.new()
	scissor.restyles = true
	scissor.position = position + Vector2(facing * (SIZE.x / 2 + 16), -30)
	var offset := _aim_point - (get_parent() as Node2D).to_global(scissor.position)
	scissor.direction = offset.normalized() if offset.length() > 1.0 else Vector2(facing, 0)
	# Close shots get at least 0.6 seconds of flight, in addition to the warning.
	scissor.speed = minf(Scissor.SPEED * (1.15 if phase() == 3 else 1.0), maxf(1.0, offset.length() / 0.6))
	get_parent().add_child.call_deferred(scissor)


func _prepare_aim() -> void:
	var candidates: Array[Player] = []
	for player: Player in get_tree().get_nodes_in_group("players"):
		if player.alive: candidates.append(player)
	_aim_target = candidates[(shots - _shots_left) % candidates.size()] if not candidates.is_empty() else null
	_aim_point = _aim_target.global_position if is_instance_valid(_aim_target) else global_position + Vector2(facing * 250, -30)
	if absf(_aim_point.x - global_position.x) > 4:
		facing = signf(_aim_point.x - global_position.x)
	_aim_locked = false
	_t = maxf(AIM_WARNING - (0.1 if phase() == 3 else 0.0), shot_gap)


func _call_overhead_snips() -> void:
	# Snapshot both positions once: move sideways after the marks appear to escape.
	# This reaches the high corner shelves without changing their collision.
	var marks: Array[Vector2] = []
	for player: Player in get_tree().get_nodes_in_group("players"):
		if not player.alive: continue
		if marks.any(func(at: Vector2): return absf(at.x - player.global_position.x) < 80.0): continue
		marks.append(player.global_position)
		var warning := Rain.new()
		warning.boss = self
		warning.target = player.global_position
		warning.delay = 0.95 if phase() == 3 else 1.15
		get_parent().add_child(warning)


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


const Doodle := preload("res://scenes/enemies/assistant_doodle.gd")


func _draw() -> void:
	Doodle.paint(self, State.keys()[state].to_lower(), _animation_time, _pose_age, facing, absf(velocity.x) > 1.0, phase() == 3, _gait_distance)
	if state == State.SHOOT and _shots_left > 0:
		var aim := to_local(_aim_point)
		var muzzle := Vector2(facing * (SIZE.x / 2 + 16), -30)
		var tint := Color("df6b72") if _aim_locked else Color("b0306a")
		for i in 8:
			draw_line(muzzle.lerp(aim, i / 8.0), muzzle.lerp(aim, (i + 0.45) / 8.0), Color(tint, 0.55), 1.5, true)
		draw_arc(aim, 13, 0, TAU, 24, tint, 2, true)
	var top := -SIZE.y
	if state == State.DAZED:
		draw_string(ThemeDB.fallback_font, Vector2(-44, top - 14), "STOMP!", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f1c40f"))


## Boss health bar at the top of the screen: name, phase and one red block per hair left.
class BossBar extends CanvasLayer:
	var boss: BarberBot
	var _panel: Control
	var _paper: StyleBoxFlat
	var _filled: StyleBoxFlat
	var _empty: StyleBoxFlat

	func _init(b: BarberBot) -> void:
		boss = b
		layer = 8

	func _ready() -> void:
		_paper = UiTheme.card(UiTheme.CREAM, UiTheme.INK, 3, 16, 8)
		_filled = UiTheme.card(UiTheme.PINK, UiTheme.INK, 2, 5, 0)
		_empty = UiTheme.card(UiTheme.LILAC, UiTheme.INK, 2, 5, 0)
		_panel = Control.new()
		_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
		_panel.offset_left = -190
		_panel.offset_right = 190
		_panel.offset_top = 10
		_panel.offset_bottom = 62
		_panel.draw.connect(_draw_bar)
		add_child(_panel)

	func _process(_delta: float) -> void:
		visible = is_instance_valid(boss) and boss.hp > 0
		_panel.queue_redraw()

	func _draw_bar() -> void:
		var ink := Color("2b2140")
		var r := Rect2(Vector2.ZERO, _panel.size)
		_panel.draw_style_box(_paper, r)
		var font := UiTheme.heading_font()
		_panel.draw_string(font, Vector2(14, 22), "THE ASSISTANT", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, ink)
		_panel.draw_string(font, Vector2(14, 22), "PHASE %d   %d/%d" % [boss.phase(), boss.hp, boss._max_hp], HORIZONTAL_ALIGNMENT_RIGHT, _panel.size.x - 28, 16, Color("b0306a"))
		var w := (_panel.size.x - 28 - (boss._max_hp - 1) * 8) / boss._max_hp
		for i in boss._max_hp:
			var seg := Rect2(14 + i * (w + 8), 30, w, 12)
			_panel.draw_style_box(_filled if i < boss.hp else _empty, seg)
