extends Node
## Plays through L2's intended solution with simulated input and checks each step.
## Run: godot --headless --path . res://tests/test_level_02.tscn   (exit code 0 = pass)

var _failures := 0
var level: Node


func _ready() -> void:
	level = load("res://scenes/levels/level_02.tscn").instantiate()
	add_child(level)
	await _frames(5)
	var a := _player(1)
	var b := _player(2)
	var turret: ScissorTurret = _first(ScissorTurret)
	var lever: Lever = _first(Lever)
	var hit_switch: HitSwitch = _first(HitSwitch)
	var door: Door = _first(Door)

	# 1. Launch: P1 on P2's head under the ledge, P2 presses skill.
	turret.take_hit(0, 10.0)
	b.global_position = Vector2(304, 240)
	a.global_position = Vector2(304, 200)
	await _frames(40)
	_check("P1 can stand on P2's head", a.is_on_floor() and absf(a.global_position.y - 216.0) < 2.0, a.global_position)
	await _tap("p2_skill")
	await _frames(90)
	_check("launch lands P1 on the lever ledge (y=112)", a.is_on_floor() and absf(a.global_position.y - 112.0) < 2.0, a.global_position)

	# 2. Normal jump from P2's head must NOT reach the ledge.
	a.global_position = Vector2(304, 200)
	await _frames(40)
	await _tap("p1_jump", 30)
	await _frames(90)
	_check("plain jump from head can't reach the ledge", a.global_position.y > 150.0, a.global_position)

	# 3. Parry without the lever: scissor goes back and jams the turret.
	b.global_position = Vector2(320, 240)
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
	a.global_position = lever.global_position + Vector2(-6, 0)
	b.global_position = Vector2(440, 240)
	b.facing = 1.0
	b.hp = b.max_hp
	turret._jam = 0.0
	turret._timer = 0.05
	await _wait_for_incoming(b)
	await _tap("p2_attack")
	await _tap("p1_skill")
	await _frames(120)
	_check("deflected scissor hits the switch", hit_switch.pressed, hit_switch.pressed)
	_check("door opens", door.is_open, door.is_open)
	await _frames(160)
	_check("spring lever has sprung back", not lever.on, lever.on)

	# 5. Getting hit by a scissor costs 1 HP.
	b.global_position = Vector2(320, 240)
	b.hp = b.max_hp
	b._invincible = 0.0
	turret._jam = 0.0
	turret._timer = 0.05
	await _wait_for_incoming(b)
	await _frames(20)
	_check("unparried scissor damages P2", b.hp == b.max_hp - 1, b.hp)

	# 6. Both players in the exit wins.
	turret.take_hit(0, 10.0)
	a.global_position = Vector2(325, 330)
	b.global_position = Vector2(345, 330)
	await _frames(20)
	_check("both players in EXIT wins", Game.has_won, Game.has_won)

	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	get_tree().quit(0 if _failures == 0 else 1)


## Waits until an incoming scissor is `distance` px in front of P2 (20 = parry range).
func _wait_for_incoming(b: Player, distance := 20.0) -> void:
	for i in 600:
		for s in get_tree().get_nodes_in_group("scissors"):
			var dx: float = s.global_position.x - b.global_position.x
			if not s.deflected and absf(dx - distance) < 6.0:
				return
		await get_tree().physics_frame
	_check("an incoming scissor reached P2", false, "timeout")


func _tap(action: String, hold_frames := 2) -> void:
	Input.action_press(action)
	await _frames(hold_frames)
	Input.action_release(action)
	await _frames(1)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _player(id: int) -> Player:
	for p in get_tree().get_nodes_in_group("players"):
		if p.player_id == id:
			return p
	return null


func _first(type: Variant) -> Node:
	for child in level.get_children():
		if is_instance_of(child, type):
			return child
	return null


func _check(what: String, ok: bool, detail: Variant) -> void:
	print("%s  %s  (%s)" % ["PASS" if ok else "FAIL", what, str(detail)])
	if not ok:
		_failures += 1
