extends PlayBot
## Bot playthrough of L2 "Return to Sender": parry + volley rings the service bells.
## Room 1 teaches it with one bell; room 2 needs two bells and a clipper bot cleared.
## Run: godot --headless --fixed-fps 60 --path . --script res://tests/test_level_02.gd

const LevelScene := preload("res://scenes/levels/level_02.tscn")


func _run() -> void:
	await load_level(LevelScene)
	await _room_1()
	if failed == 0:
		await _room_2()
	if failed == 0:
		await _restart_and_pause()
	finish()


func _room_1() -> void:
	var room := level.get_node("Rooms/Room1")
	var o: float = room.global_position.x
	var bell: HitSwitch = room.get_node("Bell")
	var door: Door = room.get_node("StaffDoor")
	var dispenser: ScissorTurret = room.get_node("Dispenser")

	# Parry alone: the scissor flies home and jams the dispenser, the bell stays quiet.
	await walk_to(p2, o + 12 * TILE)
	check(await parry_next_scissor(p2, 600), "R1: P2 parries a scissor")
	check(await wait_until(func(): return dispenser._jam > 0.0, 240), "R1: a lone parry just jams the dispenser")
	check(not bell.pressed, "R1: the bell needs more than a parry")

	await walk_to(p1, o + 20.5 * TILE)
	check(p1.global_position.y > 19 * TILE, "R1: twin-tails drops into the trench")
	var hp_before := p1.hp
	var rung := false
	for attempt in 6:
		if not await parry_next_scissor(p2, 600):
			continue
		if await volley_next(p1, 120) and await wait_until(func(): return bell.pressed, 60):
			rung = true
			break
	check(rung, "R1: parry + volley rings the bell")
	check(p1.hp == hp_before, "R1: enemy scissors fly over twin-tails in the trench")
	check(door.is_open, "R1: the bell opens the staff door")

	for p in [p2, p1]:
		await _climb_shelves(p, o)
	check(p1.global_position.y < 10 * TILE and p2.global_position.y < 10 * TILE, "R1: both climb the shelves to the door")
	await enter_exit(room, 1)


func _room_2() -> void:
	var room := level.get_node("Rooms/Room2")
	var o: float = room.global_position.x
	var door: Door = room.get_node("StaffDoor")
	var bells: Array[HitSwitch] = [room.get_node("Bell22"), room.get_node("Bell30")]
	var corridor_bot: ClipperBot = room.get_node("CorridorBot")
	var dispenser: ScissorTurret = room.get_node("Dispenser")

	check(await smash_bot(p2, room.get_node("ClipperBot")), "R2: pompadour clears the clipper bot by the stairs")
	# P2 takes the front of the parry stripes and guards while P1 slips past into the trench.
	await walk_to(p2, o + 20.5 * TILE)
	walk_to(p1, o + 22.5 * TILE)
	await guard_until(p2, func(): return p1.global_position.y > 15 * TILE and p1.is_on_floor(), 900)
	check(p2.global_position.y < 15 * TILE and p1.global_position.y > 15 * TILE, "R2: P2 on the walkway, P1 in the first trench")

	check(await _volley_until(bells[0]), "R2: volley rings the first bell")
	check(not door.is_open, "R2: one bell isn't enough")

	# The bot shields the far trench: parried scissors that P1 lets pass knock it out.
	for i in 8:
		if not is_instance_valid(corridor_bot):
			break
		await parry_next_scissor(p2, 600)
		await _ticks(60)
	check(not is_instance_valid(corridor_bot), "R2: parried scissors take out the corridor bot")

	# With the bot gone a lone parry jams the dispenser: that's P1's window to move.
	await _jam(dispenser)
	await walk_to(p1, o + 30.5 * TILE)
	check(p1.global_position.y > 15 * TILE and p1.alive, "R2: P1 moves to the far trench while it's jammed")
	check(await _volley_until(bells[1]), "R2: volley from the far trench rings the second bell")
	check(door.is_open, "R2: both bells open the staff door")

	# Jam it once more, then down the right end and back left under the walkway.
	await _jam(dispenser)
	walk_to(p1, o + 37 * TILE)
	await walk_to(p2, o + 37 * TILE)
	await _ticks(30)
	walk_to(p1, o + 21.5 * TILE)
	await walk_to(p2, o + 20.5 * TILE)
	check(await wait_until(func(): return level.banner.text.ends_with("CLEAR!"), 300), "R2: both in the exit clears L2")


## Restart (R, or the death popup) rebuilds the room: the bot and the bells come back.
## Esc pauses; Resume carries on.
func _restart_and_pause() -> void:
	await load_level(LevelScene, 1)
	var bot: ClipperBot = level.get_node("Rooms/Room2/CorridorBot")
	bot.take_hit(5)
	var bell: HitSwitch = level.get_node("Rooms/Room2/Bell22")
	bell.activated.emit()
	bell.pressed = true
	await _ticks(5)
	await press_action("restart")
	await _ticks(10)
	check(level.room_index == 1, "R restarts the same room")
	check(is_instance_valid(level.get_node_or_null("Rooms/Room2/CorridorBot")), "restart brings the clipper bot back")
	check(not level.get_node("Rooms/Room2/Bell22").pressed, "restart un-rings the bells")
	check(level.get_node("Rooms/Room2/StaffDoor").locks == 2, "restart re-locks the door")
	p1.die()
	check(await choose_on_death("Restart room"), "death popup appears")
	check(level.deaths == 1 and is_instance_valid(level.get_node_or_null("Rooms/Room2/CorridorBot")), "death restart counts the death, room fresh")

	await press_action("pause")
	check(paused and level.menu.is_open(), "Esc pauses and shows the pause menu")
	check(level.menu.button_labels() == ["Resume", "Restart room", "Main menu"], "pause menu has Resume / Restart room / Main menu")
	var t: float = level.level_time
	await _ticks(30)
	check(is_equal_approx(level.level_time, t), "the level timer stops while paused")
	level.menu.press("Resume")
	await _ticks(5)
	check(not paused and not level.menu.is_open(), "Resume closes the menu and unpauses")


## P2 parries until the dispenser is jammed for a while (parried scissors fly home).
func _jam(dispenser: ScissorTurret) -> void:
	await guard_until(p2, func(): return dispenser._jam > 2.0, 900)


## Parry, then volley from wherever P1 stands, until `bell` rings.
func _volley_until(bell: HitSwitch) -> bool:
	for attempt in 8:
		if bell.pressed:
			return true
		if not await parry_next_scissor(p2, 600):
			continue
		if await volley_next(p1, 120):
			await wait_until(func(): return bell.pressed, 60)
	return bell.pressed


## Room 1's shelves: three one-way planks, 3 tiles apart, up to the staff door.
func _climb_shelves(p: Player, o: float) -> void:
	await walk_to(p, o + 24.5 * TILE)
	await jump_up(p)
	await walk_to(p, o + 26.5 * TILE)
	await jump_up(p)
	await walk_to(p, o + 28.5 * TILE)
	await jump_up(p)
