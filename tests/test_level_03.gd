extends PlayBot
## Bot playthrough of L3: parry + carry under fire, the hair-swap chair, and the
## barber-bot boss fought with swapped haircuts. Exits non-zero if any step fails.
## Run: godot --headless --fixed-fps 60 --path . --script res://tests/test_level_03.gd

const LevelScene := preload("res://scenes/levels/level_03.tscn")


func _run() -> void:
	await load_level(LevelScene)
	await _room_1()
	if failed == 0:
		await _room_2()
	if failed == 0:
		await _room_3()
	if failed == 0:
		await _boss_unit_checks()
	finish()


func _room_1() -> void:
	var room := level.get_node("Rooms/Room1")
	var o: float = room.global_position.x
	var turret: ScissorTurret = room.get_node("Turret")
	var iron: HotIron = room.get_node("FlatIron")
	# The flat iron covers x=5-6 of the start floor: cross it right after it cools.
	await _cross_when_cold(p2, iron, o + 10 * TILE)
	check(p2.alive, "R1: P2 crosses the flat iron between heats")
	check(await parry_next_scissor(p2, 400), "R1: P2 parries a turret scissor on the ledge")
	check(await wait_until(func(): return turret._jam > 0.0, 240), "R1: the parried scissor jams the turret")

	await _cross_when_cold(p1, iron, o + 9 * TILE)
	check(p1.alive, "R1: P1 crosses the flat iron too")
	check(await wait_for_clear_window(p2, turret, 1200), "R1: P2 keeps parrying until the turret is jammed and the air is clear")
	hold(p1, "skill", true)
	await _ticks(2)
	check(p1.carrying == p2, "R1: twin-tails grabs pompadour on the ledge")
	check(await glide_jump(p1, o + 12 * TILE - 4, o + 22 * TILE, false), "R1: carry over the 9-tile pool while the turret is jammed")
	hold(p1, "skill", false)
	await _ticks(10)
	check(p1.alive and p2.alive, "R1: both land alive")

	var bot: ClipperBot = room.get_node("ClipperBot")
	check(await smash_bot(p2, bot), "R1: pompadour's dash takes out the clipper bot")
	await enter_exit(room, 1)


func _room_2() -> void:
	var room := level.get_node("Rooms/Room2")
	var o: float = room.global_position.x
	await walk_to(p1, o + 20 * TILE)
	await _ticks(5)
	check(p1.ability is Pompadour and p2.ability is TwinTails, "R2: the barber's chair swaps both haircuts")
	check(room.get_node("AfterSwapHints").visible, "R2: post-swap hints appear")
	await walk_to(p2, o + 21 * TILE)

	await walk_to(p1, o + 23 * TILE - 20)
	await tap(p1, "skill")
	await _ticks(30)
	check(not is_instance_valid(room.get_node_or_null("GelWall")), "R2: P1's new dash smashes the gel wall")

	# Volley with the roles reversed: P1 parries, P2 waits in the trench and whips.
	var dispenser: ScissorTurret = room.get_node("Dispenser")
	var bell: HitSwitch = room.get_node("Bell")
	await walk_to(p1, o + 26 * TILE)
	walk_to(p2, o + 27.5 * TILE)
	await guard_until(p1, func(): return p2.global_position.y > 19 * TILE and p2.is_on_floor(), 900)
	check(p2.global_position.y > 19 * TILE, "R2: P2 (now twin-tails) drops into the trench")
	for attempt in 8:
		if bell.pressed:
			break
		if await parry_next_scissor(p1, 600):
			await volley_next(p2, 120)
			await wait_until(func(): return bell.pressed, 60)
	check(bell.pressed, "R2: swapped volley (P1 parries, P2 whips) rings the bell")
	check(room.get_node("StaffDoor").is_open, "R2: the bell opens the staff door on the cliff")

	# Jam the dispenser, then launch from behind it (it only fires left).
	await guard_until(p1, func(): return dispenser._jam > 2.0, 900)
	await walk_to(p1, o + 31.5 * TILE)
	check(await climb_onto_head(p2, p1), "R2: P2 stands on P1's head")
	await launch_onto(p2, p1, o + 33.5 * TILE)
	check(p2.global_position.y < 13 * TILE, "R2: P1 launches P2 onto the cliff")
	await tap(p2, "skill")
	await _ticks(60)
	check(room.get_node("ChairLever").is_on, "R2: P2 pulls the lever with the new hair")
	await walk_to(p1, o + 34 * TILE)
	check(p1.global_position.y < 13 * TILE, "R2: P1 climbs the risen step")
	await enter_exit(room, 2)


## Wait for the iron to cool down, then walk across it to x.
func _cross_when_cold(p: Player, iron: HotIron, x: float) -> void:
	await wait_until(func(): return iron._cycle_time() < 0.2, 300)
	await walk_to(p, x)


func _room_3() -> void:
	var room := level.get_node("Rooms/Room3")
	var boss: BarberBot = room.get_node("BarberBot")
	var door: Door = room.get_node("BossDoor")
	check(p1.ability is Pompadour, "R3: hair stays swapped in the boss room")

	# Strategy: P2 rides on P1's head; P1 parries the bot's scissors to daze it,
	# then launches P2, who steers over the bot and glides down onto the knob.
	for cycle in 12:
		if not is_instance_valid(boss) or boss.hp <= 0:
			break
		if not p2.alive or not p1.has_rider(p2):
			await _ticks(30)
			await climb_onto_head(p2, p1)
		if not is_instance_valid(boss) or boss.hp <= 0:
			break
		if not await parry_until_dazed(p1, boss, 900):
			continue
		# Walk over with P2 riding on P1's head, then launch.
		var side := signf(p1.global_position.x - boss.global_position.x)
		await walk_to(p1, boss.global_position.x + side * 110.0, 90)
		await launch_and_stomp(p2, p1, boss)
	# Stomps can also land after the launch (e.g. stepping off a corner ledge), so judge the outcome.
	check(not is_instance_valid(boss) or boss.hp <= 0, "R3: parry + launch stomps defeat the barber bot")
	check(await wait_until(func(): return door.is_open, 60), "R3: defeating the bot opens the door")

	var exit_x: float = room.get_node("Exit").global_position.x
	await walk_to(p2, exit_x + 48)
	await walk_to(p1, exit_x + 16)
	check(await wait_until(func(): return level.banner.text.begins_with("THE END"), 300), "R3: both at the exit shows the ending")


## Direct checks of the boss rules, on a fresh copy started in the boss room.
func _boss_unit_checks() -> void:
	await load_level(LevelScene, 2)
	var boss: BarberBot = level.get_node("Rooms/Room3/BarberBot")
	check(p1.ability is Pompadour and p2.ability is TwinTails, "boss room start: hair starts swapped")

	# Corner ledge (one-way, row 16): down drops through it.
	var room_x: float = level.get_node("Rooms/Room3").global_position.x
	p1.global_position = Vector2(room_x + 2.5 * TILE, 16 * TILE - Player.HALF_SIZE.y - 4)
	check(await wait_until(func(): return p1.is_on_floor() and p1.alive, 60), "players can stand on a corner ledge")
	hold(p1, "down", true)
	check(await wait_until(func(): return p1.global_position.y > 17 * TILE, 60), "holding down drops through a one-way ledge")
	hold(p1, "down", false)
	boss.take_hit(1, 1.0)
	check(boss.state != BarberBot.State.DAZED, "boss ignores a whip-sized stun")
	boss.take_hit(1, 0.3, Vector2(300, 0))
	check(boss.hp == 3, "boss ignores dash damage")
	boss.take_hit(1, 3.0)
	check(boss.state == BarberBot.State.DAZED, "a parried scissor (3 s stun) dazes the boss")
	p2.global_position = boss.global_position + Vector2(0, -BarberBot.SIZE.y - 80)
	p2.velocity = Vector2.ZERO
	check(await wait_until(func(): return boss.hp == 2, 90), "falling onto the knob while dazed is a stomp")
	await wait_until(func(): return boss.state == BarberBot.State.WALK, 120)
	p2.global_position = boss.global_position + Vector2(0, -BarberBot.SIZE.y - 80)
	await _ticks(60)
	check(boss.hp == 2, "no stomp damage unless dazed")
	boss.state = BarberBot.State.CHARGE
	boss._t = 5.0
	check(await wait_until(func(): return boss.state == BarberBot.State.DAZED, 240), "a charge into the wall dazes the boss")



# --- Helpers ------------------------------------------------------------------

func parry_until_dazed(p: Player, boss: Object, max_ticks: int) -> bool:
	for i in max_ticks:
		if not is_instance_valid(boss):
			return false
		# Only parry dazes (4 s); a crash daze (2 s) is too short for this bot's route.
		if boss.state == BarberBot.State.DAZED and boss._t > 2.5:
			return true
		var s := _incoming(p)
		if s:
			_face(p, s.global_position.x)
			await tap(p, "attack")
		else:
			await physics_frame
	return false


## Base launches the rider; the rider steers over the boss and glides onto its knob.
func launch_and_stomp(rider: Player, base: Player, boss: Object) -> void:
	await tap(base, "skill")
	for i in 240:
		if not is_instance_valid(boss) or boss.state != BarberBot.State.DAZED or rider.is_on_floor() and i > 10:
			break
		var dx: float = boss.global_position.x - rider.global_position.x
		hold(rider, "right", dx > 16.0)
		hold(rider, "left", dx < -16.0)
		hold(rider, "skill", rider.velocity.y > 0.0)
		await physics_frame
	for a in ["right", "left", "skill"]:
		hold(rider, a, false)
	await _ticks(20)
