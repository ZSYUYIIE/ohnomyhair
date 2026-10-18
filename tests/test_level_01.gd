extends PlayBot
## Bot playthrough of L1: drives both players with simulated input through all
## three rooms (R3: the sling-dash combo) and checks each puzzle step. Exits non-zero if any step fails.
## Run: godot --headless --fixed-fps 60 --path . --script res://tests/test_level_01.gd

const LevelScene := preload("res://scenes/levels/level_01.tscn")


func _run() -> void:
	await load_level(LevelScene)
	check(p1.is_on_floor() and p2.is_on_floor(), "both players spawn on the floor")

	await _room_1()
	if failed == 0:
		await _room_2()
	if failed == 0:
		await _room_3()
	stop_logging()  # the rest are counter-checks that die on purpose
	if failed == 0:
		await _carry_alone_fails()
	if failed == 0:
		await _death_respawns()

	finish()


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
	await enter_exit(room, 1)


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
	await enter_exit(room, 2)


## Gel Curtain: carry off the counter, and P2 (hanging) presses skill mid-flight to be
## flung through the regrowing gel; P1, lighter now, glides through the hole.
func _room_3() -> void:
	var room := level.get_node("Rooms/Room3")
	var o: float = room.global_position.x
	var curtain: BreakableWall = room.get_node("GelCurtain")
	await walk_to(p2, o + 15 * TILE)
	await walk_to(p1, o + 14 * TILE)
	check(p1.global_position.y < 13 * TILE and p2.global_position.y < 13 * TILE, "R3: both climb the stairs onto the counter")
	hold(p1, "skill", true)
	await _ticks(2)
	check(p1.carrying == p2, "R3: twin-tails grabs pompadour on the counter")
	hold(p1, "right", true)
	await wait_until(func(): return p1.global_position.x >= o + 16 * TILE + 10, 120)
	hold(p1, "jump", true)
	await wait_until(func(): return p1.global_position.x >= o + 19.5 * TILE, 120)
	await tap(p2, "skill")
	check(p2.carried_by == null, "R3: P2 presses skill while hanging and gets flung")
	await wait_until(func(): return not p2.ability.is_slinging(), 60)
	check(p2.global_position.x > o + 25 * TILE, "R3: the sling dash punches through the gel curtain")
	await wait_until(func(): return p1.is_on_floor(), 240)
	for a in ["right", "jump", "skill"]:
		hold(p1, a, false)
	await _ticks(20)
	check(p1.alive and p2.alive and p1.global_position.x > o + 25 * TILE, "R3: twin-tails glides through the hole before it closes")
	await _ticks(150)
	check(curtain.is_solid(), "R3: the curtain grows back behind them")

	await walk_to(p2, o + 37.5 * TILE)
	await walk_to(p1, o + 36.5 * TILE)
	check(await wait_until(func(): return level.banner.text.contains("CLEAR!"), 120), "R3: both at the back door clears L1")


## Without the fling: a plain carry flies into the curtain and drops both into the dye.
func _carry_alone_fails() -> void:
	await load_level(LevelScene, 2)
	var o: float = level.get_node("Rooms/Room3").global_position.x
	await walk_to(p2, o + 15 * TILE)
	await walk_to(p1, o + 14 * TILE)
	hold(p1, "skill", true)
	await _ticks(2)
	hold(p1, "right", true)
	await wait_until(func(): return p1.global_position.x >= o + 16 * TILE + 10, 120)
	hold(p1, "jump", true)
	await wait_until(func(): return not p1.alive or not p2.alive, 300)
	for a in ["right", "jump", "skill"]:
		hold(p1, a, false)
	check(not p1.alive or not p2.alive or p1.global_position.x < o + 23 * TILE, "R3: a carry without the fling can't get past the curtain")
	await _ticks(60)


## Dying opens the popup; "Restart room" rebuilds the room (props reset), keeps the room
## and counts the death.
func _death_respawns() -> void:
	await load_level(LevelScene, 1)
	var lever: Lever = level.get_node("Rooms/Room2/Lever")
	lever.interact(p1)
	check(lever.is_on, "setup: the room-2 lever is pulled")
	p2.global_position = level.get_node("Rooms/Room2/DyePool").global_position + Vector2(100, 20)
	check(await wait_until(func(): return not p2.alive, 30), "dye pool kills")
	check(await choose_on_death("Restart room"), "a death opens the restart / main menu popup")
	check(not paused, "restarting unpauses the game")
	check(level.room_index == 1 and p1.alive and p2.alive, "restart keeps the room and both are back")
	check(not level.get_node("Rooms/Room2/Lever").is_on, "restart resets the room: the lever is back up")
	check(level.deaths == 1, "the death is counted across the restart")
	var spawn: Vector2 = level.rooms[1].spawn_point(2)
	check(p2.global_position.distance_to(spawn) < 4.0, "restart puts P2 back at the room spawn")
