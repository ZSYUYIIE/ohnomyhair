extends SceneTree
## Plays through L2's intended solution with simulated input and checks each step
## (ported from the original 640x360 prototype test; coordinates are now tiles x 32).
## Run: godot --headless --fixed-fps 60 --path . --script res://tests/test_level_02.gd

const TILE := 32.0
const LevelScene := preload("res://scenes/levels/level_02.tscn")

var passed := 0
var failed := 0
var level: Level
var a: Player
var b: Player


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	level = LevelScene.instantiate()
	root.add_child(level)
	a = level.get_node("Players/P1")
	b = level.get_node("Players/P2")
	var room := level.get_node("Rooms/Room1")
	var turret: ScissorTurret = room.get_node("Turret")
	var lever: Lever = room.get_node("Lever")
	var hit_switch: HitSwitch = room.get_node("Switch")
	var door: Door = room.get_node("Door")
	var bot: ClipperBot = room.get_node("ClipperBot")
	await _frames(10)

	# 0. Combat: whip stuns the clipper bot, a dash damages it.
	a.global_position = bot.global_position + Vector2(-40, -Player.HALF_SIZE.y)
	a.facing = 1.0
	await _frames(2)
	await _tap("p1_attack")
	_check("hair whip stuns the clipper bot", bot.stun > 0.0, bot.stun)
	b.global_position = bot.global_position + Vector2(-70, -Player.HALF_SIZE.y)
	b.facing = 1.0
	var hp_before := bot.hp
	await _tap("p2_skill")
	await _frames(15)
	_check("pompadour dash damages the clipper bot", not is_instance_valid(bot) or bot.hp < hp_before, hp_before)

	# 1. Launch: P1 on P2's head under the ledge, P2 presses skill.
	turret.take_hit(0, 30.0)
	_place(b, 19.5, 15)
	a.global_position = b.global_position + Vector2(0, -60)
	await _frames(40)
	_check("P1 can stand on P2's head", a.is_on_floor() and b.has_rider(a), a.global_position)
	await _tap("p2_skill")
	await _frames(90)
	_check("launch lands P1 on the lever ledge", a.is_on_floor() and absf(_feet(a) - 7 * TILE) < 2.0, a.global_position)

	# 2. A normal jump from P2's head must NOT reach the ledge.
	a.global_position = b.global_position + Vector2(0, -60)
	await _frames(40)
	await _tap("p1_jump", 30)
	await _frames(90)
	_check("plain jump from head can't reach the ledge", _feet(a) > 10 * TILE, a.global_position)

	# 3. Parry without the lever: scissor goes back and jams the turret.
	_place(b, 20, 15)
	b.facing = 1.0
	turret._jam = 0.0
	turret._timer = 0.05
	await _wait_for_incoming(b)
	await _tap("p2_attack")
	await _frames(150)
	_check("unaided parry jams the turret", turret._jam > 0.0, turret._jam)
	_check("switch still off", not hit_switch.pressed, hit_switch.pressed)

	# 4. Parry + spring lever: scissor bends up into the switch, door opens.
	#    Regression for playtest 1: P2 parries right beside the plate and P1 pulls just after,
	#    so the plate rises while the scissor already overlaps it.
	a.global_position = lever.global_position + Vector2(-12, 16 - Player.HALF_SIZE.y)
	_place(b, 27.5, 15)
	b.facing = 1.0
	turret._jam = 0.0
	turret._timer = 0.05
	await _wait_for_incoming(b)
	await _tap("p2_attack")
	await _tap("p1_skill")
	await _frames(120)
	_check("deflected scissor hits the switch", hit_switch.pressed, hit_switch.pressed)
	_check("door opens", door.is_open, door.is_open)
	await _frames(160)
	_check("spring lever has sprung back", not lever.is_on, lever.is_on)

	# 5. Getting hit by a scissor costs 1 HP.
	_place(b, 20, 15)
	b.hp = b.max_hp
	b._invincible = 0.0
	turret._jam = 0.0
	turret._timer = 0.05
	await _wait_for_incoming(b)
	await _frames(20)
	_check("unparried scissor damages P2", b.hp == b.max_hp - 1, b.hp)

	# 6. Both players in the exit clears the level.
	turret.take_hit(0, 30.0)
	_place(a, 20.5, 21)
	_place(b, 21.5, 21)
	var cleared := false
	for i in 60:
		await physics_frame
		if level.banner.text.ends_with("CLEAR!"):
			cleared = true
			break
	_check("both players in EXIT clears L2", cleared, level.banner.text)

	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


## Put a player's feet on top of tile row `floor_row`, centered on tile column `col`.
func _place(p: Player, col: float, floor_row: int) -> void:
	p.global_position = Vector2(col * TILE, floor_row * TILE - Player.HALF_SIZE.y)
	p.velocity = Vector2.ZERO


func _feet(p: Player) -> float:
	return p.global_position.y + Player.HALF_SIZE.y


## Waits until an incoming scissor is `distance` px in front of P2 (40 = parry range).
func _wait_for_incoming(p: Player, distance := 40.0) -> void:
	for i in 600:
		for s in get_nodes_in_group("scissors"):
			var dx: float = s.global_position.x - p.global_position.x
			if not s.deflected and absf(dx - distance) < 10.0:
				return
		await physics_frame
	_check("an incoming scissor reached P2", false, "timeout")


func _tap(action: String, hold_frames := 2) -> void:
	Input.action_press(action)
	await _frames(hold_frames)
	Input.action_release(action)
	await _frames(1)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _check(what: String, ok: bool, detail: Variant) -> void:
	print("  %s  %s  (%s)" % ["ok  " if ok else "FAIL", what, str(detail)])
	if ok:
		passed += 1
	else:
		failed += 1
		push_error("FAIL " + what)
