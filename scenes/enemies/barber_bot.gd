class_name BarberBot
extends CharacterBody2D
## L4 boss: the runaway barber robot. Origin is at the feet.
## Loop: WALK toward a player -> SHOOT 3 scissors / WINDUP + CHARGE (alternating).
## Three phases, one per hair of HP, each announced with a banner and shown on the boss bar:
##   1 - as above;   2 - it calls for backup (`backup_called`: wire it to a WaveArena);
##   3 - furious: faster, longer scissor bursts, shorter wind-up.
## It only takes damage from being stomped on its head knob while DAZED. It gets dazed by
## a parried scissor (3 s) or by crashing into a wall at the end of a charge (shorter).
## Whips, dashes and parry swings just bounce off ("too big").
## Each state is a function that returns the next state, or `stay` to remain.

signal defeated
signal backup_called

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
var _max_hp := 3
var _bar: BossBar


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
	if _bar == null:
		# Made on the first tick, which only comes once its room is the current one.
		_bar = BossBar.new(self)
		add_child(_bar)
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
		Level.banner_for(self, "The barber bot is down!", 2.0)
		defeated.emit()
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.8)
		tween.tween_callback(queue_free)
	elif hp == _max_hp - 1:
		Level.banner_for(self, "PHASE 2: it calls for backup!", 1.8)
		backup_called.emit()
	elif hp == 1:
		_enrage()


## Phase 3: one hair left and it's furious.
func _enrage() -> void:
	Level.banner_for(self, "PHASE 3: it's furious!", 1.8)
	walk_speed *= 1.35
	charge_speed *= 1.2
	windup_time = 0.5
	shots = 5
	shot_gap = 0.36


func phase() -> int:
	return clampi(_max_hp - hp + 1, 1, 3)


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


const ART := preload("res://assets/art/enemies/enemy_barber_bot.png")


func _draw() -> void:
	# Head down, squashed low while charging: reads as "jump over me".
	var squash := Vector2(1.15, CHARGE_HEIGHT / SIZE.y) if state == State.CHARGE else Vector2.ONE
	var frame := 0  # normal | dazed (glowing knob) | hurt flash
	match state:
		State.DAZED: frame = 1
		State.HURT, State.WINDUP: frame = 2 if int(_flash * 40.0) % 2 == 0 else 0
	draw_set_transform(Vector2.ZERO, 0.0, squash * Vector2(facing, 1.0))
	# Furious (phase 3): it throbs red.
	var tint := Color(1, 0.62, 0.6) if phase() == 3 and state != State.DAZED and int(Time.get_ticks_msec() / 150) % 2 == 0 else Color.WHITE
	draw_texture_rect_region(ART, Rect2(-72, -140, 144, 144), Rect2(frame * 144, 0, 144, 144), tint)
	draw_set_transform(Vector2.ZERO, 0.0, squash)
	var top := -SIZE.y
	if state == State.DAZED:
		draw_string(ThemeDB.fallback_font, Vector2(-44, top - 14), "STOMP!", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f1c40f"))
	for i in hp:
		var bar := Rect2(-SIZE.x / 2 + i * 34, top - 34 if state != State.DAZED else top - 44, 28, 7)
		draw_rect(bar.grow(1.5), Color("2b2140"))
		draw_rect(bar, Color("e74c3c"))


## Boss health bar at the top of the screen: name, phase and one red block per hair left.
class BossBar extends CanvasLayer:
	var boss: BarberBot
	var _panel: Control

	func _init(b: BarberBot) -> void:
		boss = b
		layer = 8

	func _ready() -> void:
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
		_panel.draw_rect(r, Color("fff6ea"))
		_panel.draw_rect(r, ink, false, 3.0)
		var font := ThemeDB.fallback_font
		_panel.draw_string(font, Vector2(14, 22), "THE BARBER BOT", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, ink)
		_panel.draw_string(font, Vector2(14, 22), "PHASE %d" % boss.phase(), HORIZONTAL_ALIGNMENT_RIGHT, _panel.size.x - 28, 16, Color("b0306a"))
		var w := (_panel.size.x - 28 - 2 * 8) / boss._max_hp
		for i in boss._max_hp:
			var seg := Rect2(14 + i * (w + 8), 30, w, 12)
			_panel.draw_rect(seg, Color("e74c3c") if i < boss.hp else Color(ink, 0.15))
			_panel.draw_rect(seg, ink, false, 2.0)
