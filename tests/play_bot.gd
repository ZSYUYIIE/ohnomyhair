class_name PlayBot
extends SceneTree
## Base for level playthrough tests: simulated input for both players plus a
## pass/fail counter. A test extends this, loads its level in _run() and ends
## with finish().

const TILE := 32.0

var passed := 0
var failed := 0
var level: Level
var p1: Player
var p2: Player


func _initialize() -> void:
	_run.call_deferred()


## Override: the playthrough.
func _run() -> void:
	pass


func load_level(scene: PackedScene, start_room := 0) -> void:
	if level:
		level.queue_free()
		await _ticks(2)
	level = scene.instantiate()
	level.start_room = start_room
	root.add_child(level)
	p1 = level.get_node("Players/P1")
	p2 = level.get_node("Players/P2")
	await _ticks(20)


func finish() -> void:
	for action in InputMap.get_actions():
		Input.action_release(action)
	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


## Both walk into the room's exit and wait for the pan to room `next_index`.
func enter_exit(room: Node, next_index: int) -> void:
	var exit_x: float = room.get_node("Exit").global_position.x
	await walk_to(p2, exit_x + 48)
	await walk_to(p1, exit_x + 16)
	var moved := await wait_until(func(): return level.room_index == next_index and not level._busy, 180)
	check(moved, "room %d: both in the exit pans to the next room" % next_index)
	await _ticks(10)


# --- Bot helpers --------------------------------------------------------------

func hold(p: Player, action: String, on: bool) -> void:
	var name := "p%d_%s" % [p.player_id, action]
	if on:
		Input.action_press(name)
	else:
		Input.action_release(name)


func tap(p: Player, action: String) -> void:
	hold(p, action, true)
	await physics_frame
	hold(p, action, false)
	await physics_frame


func _ticks(n: int) -> void:
	for i in n:
		await physics_frame


func wait_until(cond: Callable, max_ticks: int) -> bool:
	for i in max_ticks:
		if cond.call():
			return true
		await physics_frame
	return cond.call()


## Walk toward x, hopping up any step in the way. Local x is in level space.
func walk_to(p: Player, x: float, max_ticks := 600) -> void:
	for i in max_ticks:
		var dx := x - p.global_position.x
		if absf(dx) < 6.0:
			break
		hold(p, "right", dx > 0.0)
		hold(p, "left", dx < 0.0)
		if p.is_on_floor() and p.is_on_wall():
			# Hold jump for the full arc; a 1-frame tap is a short hop (variable jump).
			hold(p, "jump", true)
			await _ticks(18)
			hold(p, "jump", false)
		else:
			await physics_frame
	hold(p, "right", false)
	hold(p, "left", false)
	await wait_until(func(): return p.is_on_floor() and absf(p.velocity.x) < 1.0, 60)


## Run right, jump at take_off_x holding jump + skill (glide), land past land_x.
## jump_frames > 0 releases jump after that many frames (a tap); otherwise it's held.
func glide_jump(p: Player, take_off_x: float, land_x: float, release_skill := true, jump_frames := -1) -> bool:
	hold(p, "skill", true)
	hold(p, "right", true)
	var jumped := false
	for i in 400:
		await physics_frame
		if not jumped and p.global_position.x >= take_off_x:
			hold(p, "jump", true)
			jumped = true
		elif jumped and jump_frames > 0:
			jump_frames -= 1
			if jump_frames == 0:
				hold(p, "jump", false)
		elif jumped and p.is_on_floor() and p.global_position.x > land_x:
			break
	hold(p, "right", false)
	hold(p, "jump", false)
	if release_skill:
		hold(p, "skill", false)
	await _ticks(10)
	return p.alive and p.is_on_floor() and p.global_position.x > land_x


func climb_onto_head(rider: Player, base: Player) -> bool:
	await walk_to(rider, base.global_position.x - 70.0)
	hold(rider, "right", true)
	hold(rider, "jump", true)
	await wait_until(func(): return rider.global_position.x >= base.global_position.x - 14.0, 60)
	hold(rider, "right", false)
	hold(rider, "jump", false)
	await wait_until(func(): return rider.is_on_floor(), 60)
	await _ticks(5)
	return rider.global_position.y < base.global_position.y - 30.0


## Base presses skill to launch the rider, who steers right and stops near stop_x.
func launch_onto(rider: Player, base: Player, stop_x: float) -> void:
	await tap(base, "skill")
	hold(rider, "right", true)
	await wait_until(func(): return rider.global_position.x >= stop_x - 20.0, 120)
	hold(rider, "right", false)
	await wait_until(func(): return rider.is_on_floor(), 120)
	await walk_to(rider, stop_x)


func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("  ok   ", label)
	else:
		failed += 1
		push_error("FAIL " + label)
		print("  FAIL ", label, "   p1=", p1.global_position, " p2=", p2.global_position)
