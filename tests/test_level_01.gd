extends SceneTree
## Bot playthrough of L1: drives both players with simulated input through all
## three rooms and checks each puzzle step. Exits non-zero if any step fails.
## Run: godot --headless --fixed-fps 60 --path . --script res://tests/test_level_01.gd

const TILE := 32.0
const LevelScene := preload("res://scenes/levels/level_01.tscn")

var passed := 0
var failed := 0
var level: Level
var p1: Player
var p2: Player


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	level = LevelScene.instantiate()
	root.add_child(level)
	p1 = level.get_node("Players/P1")
	p2 = level.get_node("Players/P2")
	await _ticks(30)
	check(p1.is_on_floor() and p2.is_on_floor(), "both players spawn on the floor")

	await _room_1()
	if failed == 0:
		await _room_2()
	if failed == 0:
		await _room_3()
	if failed == 0:
		await _death_respawns()

	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _room_1() -> void:
	var room := level.get_node("Rooms/Room1")
	await walk_to(p2, 17 * TILE - 20)
	await tap(p2, "skill")
	await _ticks(30)
	check(not is_instance_valid(room.get_node_or_null("GelWall")), "R1: pompadour dash smashes the gel wall")

	await walk_to(p1, 20 * TILE)
	check(await glide_jump(p1, 22 * TILE - 4, 32 * TILE + 20), "R1: twin-tails glides over the 10-tile pit")
	await walk_to(p1, 34 * TILE + 16)
	await tap(p1, "skill")
	check(room.get_node("Lever").is_on, "R1: twin-tails pulls the lever")
	await _ticks(60)

	await walk_to(p2, 33 * TILE)
	check(p2.global_position.y < 15 * TILE, "R1: pompadour crosses the lowered bridge")
	await _enter_exit(room, 1)


func _room_2() -> void:
	var room := level.get_node("Rooms/Room2")
	var o: float = room.global_position.x
	await walk_to(p2, o + 9.5 * TILE)
	await walk_to(p1, o + 8 * TILE)
	hold(p1, "skill", true)
	await _ticks(2)
	check(p1.carrying == p2, "R2: twin-tails grabs pompadour")
	# Sloppy on purpose (real players did this): P1 only taps jump, P2 mashes jump while carried.
	hold(p2, "jump", true)
	check(await glide_jump(p1, o + 12 * TILE - 4, o + 21 * TILE, false, 6), "R2: sloppy carry (tap jump, P2 mashing jump) still crosses the dye")
	hold(p2, "jump", false)
	hold(p1, "skill", false)
	await _ticks(10)
	check(p2.alive and p2.global_position.x > o + 20 * TILE, "R2: pompadour lands safely")

	await walk_to(p2, o + 24 * TILE)
	check(await climb_onto_head(p1, p2), "R2: twin-tails stands on pompadour's head")
	await launch_onto(p1, p2, o + 30 * TILE + 16)
	check(p1.global_position.y < 13 * TILE, "R2: launch puts twin-tails on the cliff")
	await tap(p1, "skill")
	await _ticks(60)
	check(room.get_node("Lever").is_on, "R2: lever raises the step")
	await walk_to(p2, o + 32 * TILE)
	check(p2.global_position.y < 13 * TILE, "R2: pompadour climbs the step onto the cliff")
	await _enter_exit(room, 2)


func _room_3() -> void:
	var room := level.get_node("Rooms/Room3")
	var o: float = room.global_position.x
	var spikes: PeriodicSpikes = room.get_node("CombSpikes")
	await walk_to(p2, o + 6 * TILE)
	check(await climb_onto_head(p1, p2), "R3: twin-tails stands on pompadour's head")
	await launch_onto(p1, p2, o + 10 * TILE + 16)
	check(p1.global_position.y < 13 * TILE, "R3: launch puts twin-tails on the deck")
	await tap(p1, "skill")
	await _ticks(60)
	await walk_to(p2, o + 11 * TILE)
	check(p2.global_position.y < 13 * TILE, "R3: pompadour climbs up after the lever")

	for p in [p2, p1]:
		await wait_until(func(): return spikes._cycle_time() < 0.1, 300)
		await walk_to(p, o + 17.2 * TILE if p == p2 else o + 16 * TILE)
	check(p1.alive and p2.alive, "R3: both cross the comb spikes between pops")

	hold(p1, "skill", true)
	await _ticks(2)
	check(p1.carrying == p2, "R3: grab on the deck edge")
	check(await glide_jump(p1, o + 18 * TILE - 4, o + 29 * TILE, false), "R3: carry over the big dye pool")
	hold(p1, "skill", false)
	await _ticks(10)
	check(p2.alive, "R3: pompadour survives the landing")

	await walk_to(p2, o + 33 * TILE - 20)
	await tap(p2, "skill")
	await _ticks(30)
	check(not is_instance_valid(room.get_node_or_null("GelWall")), "R3: second gel wall smashed")
	await walk_to(p2, o + 37.5 * TILE)
	await walk_to(p1, o + 36.5 * TILE)
	check(await wait_until(func(): return level.banner.text.ends_with("CLEAR!"), 120), "R3: both at the back door clears L1")


func _death_respawns() -> void:
	# Restart from a fresh copy and drop P2 into the room-2 dye pool.
	level.queue_free()
	await _ticks(2)
	level = LevelScene.instantiate()
	level.start_room = 1
	root.add_child(level)
	p1 = level.get_node("Players/P1")
	p2 = level.get_node("Players/P2")
	await _ticks(20)
	var spawn := p2.global_position
	p2.global_position = level.get_node("Rooms/Room2/DyePool").global_position + Vector2(100, 20)
	check(await wait_until(func(): return not p2.alive, 30), "dye pool kills")
	check(await wait_until(func(): return p2.alive, 60), "both respawn after a death")
	check(p2.global_position.distance_to(spawn) < 4.0, "respawn puts P2 back at the room spawn")


func _enter_exit(room: Node, next_index: int) -> void:
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
