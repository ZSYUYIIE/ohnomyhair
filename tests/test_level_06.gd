extends PlayBot
## Bot playthrough of L6 (the finale; it was L4): parry + carry under fire, the hair-swap chair, three waves of
## robots, and the barber-bot boss (with its phases) fought with swapped haircuts.
## Exits non-zero if any step fails.
## Run: godot --headless --fixed-fps 60 --path . --script res://tests/test_level_06.gd

const LevelScene := preload("res://scenes/levels/level_06.tscn")


func _run() -> void:
	await load_level(LevelScene)
	await _room_1()
	if failed == 0:
		await _room_2()
	if failed == 0:
		await _room_3()
	if failed == 0:
		await _room_4()
	stop_logging()  # unit checks put players in harm's way on purpose
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
	# Grab works from beside, never from on top of each other: step next to P2 first
	# (the hop onto the ledge can land P1 on P2's head).
	await walk_to(p1, p2.global_position.x - 30.0)
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

	# Hair Catch with the roles reversed: P1 parries, P2 catches in the trench and tosses.
	var dispenser: ScissorTurret = room.get_node("Dispenser")
	var bell: HitSwitch = room.get_node("Bell")
	await walk_to(p1, o + 26 * TILE)
	# P2 has to step out in front of P1 to reach the trench: jam the dispenser first.
	await guard_until(p1, func(): return dispenser._jam > 2.0, 900)
	await walk_to(p2, o + 28 * TILE)
	await wait_until(func(): return p2.is_on_floor(), 60)
	check(p2.global_position.y > 19 * TILE, "R2: P2 (now twin-tails) drops into the trench")
	for attempt in 8:
		if bell.pressed:
			break
		if await parry_next_scissor(p1, 600):
			await catch_and_toss(p2, 120)
			await wait_until(func(): return bell.pressed, 60)
	check(bell.pressed, "R2: swapped hair catch (P1 parries, P2 catches) rings the bell")
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


## Rush Hour: three waves. P2 (twin-tails) waits up on the left shelf; P1 (pompadour)
## fights for real: parries scissors coming at her, hops hot irons, and dashes robots apart.
func _room_3() -> void:
	var room := level.get_node("Rooms/Room3")
	var o: float = room.global_position.x
	var arena: WaveArena = room.get_node("Waves")
	var door: Door = room.get_node("ArenaDoor")
	var dispenser: ScissorTurret = room.get_node("Dispenser")
	var iron: HotIron = room.get_node("IronLeft")
	check(dispenser.process_mode == Node.PROCESS_MODE_DISABLED and not iron.active and not door.is_open,
			"R3: the dispenser and irons sleep and the door is shut before the waves")
	await walk_to(p2, o + 7.5 * TILE)
	await jump_up(p2)
	check(p2.global_position.y < 16 * TILE, "R3: P2 waits up on the shelf")
	await walk_to(p1, o + 16 * TILE)
	for wave in 3:
		check(await wait_until(func(): return arena.wave == wave and arena.robots_left() > 0, 600),
				"R3: wave %d drops its robots through the vents" % (wave + 1))
		if wave == 0:
			check(level.banner.text == "WAVE 1 / 3", "R3: a banner announces the wave")
		if wave == 1:
			check(dispenser.process_mode == Node.PROCESS_MODE_INHERIT, "R3: wave 2 wakes the scissor dispenser")
		if wave == 2:
			check(iron.active, "R3: wave 3 heats the flat irons")
		check(await _fight_wave(arena, 3600), "R3: P1 scraps wave %d" % (wave + 1))
	check(await wait_until(func(): return door.is_open, 120), "R3: clearing the last wave opens the door")
	check(not iron.active and dispenser.process_mode == Node.PROCESS_MODE_DISABLED, "R3: then the hazards switch off")
	check(room.get_children().filter(func(n): return n is GrowthTonic).size() >= 2, "R3: growth tonics appear for the boss")
	check(p1.alive and p2.alive, "R3: both survive the rush (P1 hair left: %d)" % p1.hp)
	await enter_exit(room, 3)


## P1 parries anything flying at her, waits for a hot (or heating) iron in her way to
## cool, grabs a tonic when down to her last hair, and dashes the nearest robot from
## about 3.5 tiles out. True once the wave is scrapped.
func _fight_wave(arena: WaveArena, max_ticks: int) -> bool:
	var irons: Array = arena.get_parent().get_children().filter(func(n): return n is HotIron)
	for i in max_ticks:
		if arena.robots_left() == 0 and arena._warning.is_empty():
			break
		if not p1.alive:
			break
		var s := _incoming(p1)
		if s:
			_face(p1, s.global_position.x)
			await tap(p1, "attack")
			continue
		# Down to the last hair: head for a tonic on the counter first (same careful walk).
		var tonics: Array = arena.get_parent().get_children().filter(func(n): return n is GrowthTonic)
		var tonic: Node2D = tonics[0] if p1.hp <= 1 and not tonics.is_empty() else null
		var target: Node2D = null
		for r in arena.robots:
			if is_instance_valid(r) and (target == null or absf(r.global_position.x - p1.global_position.x) < absf(target.global_position.x - p1.global_position.x)):
				target = r
		if target == null and tonic == null:
			await physics_frame
			continue
		var stand: float
		if tonic:
			stand = tonic.global_position.x
			if absf(stand - p1.global_position.x) <= 10.0:
				await jump_up(p1)
				continue
		else:
			var side := signf(p1.global_position.x - target.global_position.x)
			stand = target.global_position.x + (side if side != 0.0 else -1.0) * 110.0
		var dx: float = stand - p1.global_position.x
		if absf(dx) > 10.0:
			hold(p1, "right", dx > 0.0)
			hold(p1, "left", dx < 0.0)
			if p1.is_on_floor() and p1.is_on_wall():  # the counter: hop over it
				hold(p1, "jump", true)
				await _ticks(18)
				hold(p1, "jump", false)
			# Never step onto an iron that is hot or about to be: wait for it to cool
			# (still parrying). Already standing on one: keep going, get off it.
			var ahead: float = p1.global_position.x + signf(dx) * 30.0
			for iron: HotIron in irons:
				var span := Rect2(iron.global_position.x - Player.HALF_SIZE.x, 0, iron.size.x + 2 * Player.HALF_SIZE.x, 1)
				var on_it := span.has_point(Vector2(p1.global_position.x, 0.5))
				if (iron.is_active() or iron._is_warning()) and not on_it and span.has_point(Vector2(ahead, 0.5)):
					hold(p1, "right", false)
					hold(p1, "left", false)
			await physics_frame
			continue
		hold(p1, "right", false)
		hold(p1, "left", false)
		_face(p1, target.global_position.x)
		await tap(p1, "skill")
		await _ticks(20)
	for a in ["right", "left", "jump"]:
		hold(p1, a, false)
	return p1.alive and arena.robots_left() == 0


## The boss fight as three rounds of its real chain: a parried scissor dazes the bot,
## P1 (pompadour) launches P2 (twin-tails) off their head, P2 steers and glides onto
## the knob. Each round starts from a fixed setup next to the bot - a dodging,
## parrying bot strong enough to survive the whole fight on its own would test the
## bot more than the game. The rules themselves are unit-checked below.
func _room_4() -> void:
	var room := level.get_node("Rooms/Room4")
	var boss: BarberBot = room.get_node("BarberBot")
	var door: Door = room.get_node("BossDoor")
	var backup: WaveArena = room.get_node("Backup")
	var floor_y: float = 19 * TILE - Player.HALF_SIZE.y
	check(p1.ability is Pompadour, "R4: hair stays swapped in the boss room")

	for round in 3:
		if not is_instance_valid(boss) or boss.hp <= 0:
			break
		await wait_until(func(): return boss.state == BarberBot.State.WALK, 300)
		var side := 1.0 if boss.global_position.x < room.global_position.x + 20 * TILE else -1.0
		p1.global_position = Vector2(boss.global_position.x + side * 140.0, floor_y)
		p2.global_position = p1.global_position + Vector2(0, -2 * Player.HALF_SIZE.y - 4)
		p1.velocity = Vector2.ZERO
		p2.velocity = Vector2.ZERO
		# A scissor P1 parried, flying back into the bot.
		var s := Scissor.new()
		s.direction = Vector2(-side, 0)
		room.add_child(s)
		s.global_position = p1.global_position + Vector2(-side * 40.0, -10.0)
		s.deflect()
		s.direction = Vector2(-side, 0)
		s.rotation = s.direction.angle()
		check(await wait_until(func(): return boss.state == BarberBot.State.DAZED, 90), "R4 round %d: a parried scissor dazes the bot" % (round + 1))
		await wait_until(func(): return p1.has_rider(p2), 30)
		var hp_before := boss.hp
		await launch_and_stomp(p2, p1, boss)
		check(not is_instance_valid(boss) or boss.hp < hp_before, "R4 round %d: launch + glide stomps its head" % (round + 1))
		if round == 0:
			check(boss.phase() == 2 and level.banner.text.begins_with("PHASE 2"), "R4: the first stomp starts phase 2 (banner)")
			check(await wait_until(func(): return backup.robots_left() == 2, 120), "R4: phase 2 calls two backup robots through the corner vents")
		elif round == 1:
			check(boss.phase() == 3 and boss.shots == 5 and level.banner.text.begins_with("PHASE 3"), "R4: the second stomp makes it furious: phase 3, 5-scissor bursts")
		await _ticks(30)
	check(not is_instance_valid(boss) or boss.hp <= 0, "R4: three stomps defeat the barber bot")
	check(await wait_until(func(): return door.is_open, 60), "R4: defeating the bot opens the door")
	await _ticks(2)
	check(backup.robots_left() == 0, "R4: its backup robots power down with it")

	var exit_x: float = room.get_node("Exit").global_position.x
	await walk_to(p2, exit_x + 48)
	await walk_to(p1, exit_x + 16)
	check(await wait_until(func(): return level.banner.text.begins_with("THE END"), 300), "R4: both at the exit shows the ending")


## Direct checks of the boss rules, on a fresh copy started in the boss room.
func _boss_unit_checks() -> void:
	await load_level(LevelScene, 3)
	var boss: BarberBot = level.get_node("Rooms/Room4/BarberBot")
	check(p1.ability is Pompadour and p2.ability is TwinTails, "boss room start: hair starts swapped")
	await _ticks(2)
	var bars := boss.get_children().filter(func(n): return n is BarberBot.BossBar)
	check(bars.size() == 1 and bars[0].visible, "a boss bar shows its name, phase and hair left")

	# Corner ledge (one-way, row 16): down drops through it.
	var room_x: float = level.get_node("Rooms/Room4").global_position.x
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

	# The charge ducks low (CHARGE_HEIGHT): a player at the top of a full jump clears it,
	# one standing on the floor doesn't.
	var top_of_jump := Vector2(boss.global_position.x, boss.global_position.y - p1.jump_height - Player.HALF_SIZE.y)
	p1.global_position = top_of_jump
	boss.state = BarberBot.State.CHARGE
	var hp_before := p1.hp
	p1.make_invincible(0.0)
	p1._invincible = 0.0
	boss._hurt_touching_players()
	check(p1.hp == hp_before, "a full jump clears the ducking charge")
	p1.global_position = Vector2(boss.global_position.x, boss.global_position.y - Player.HALF_SIZE.y)
	boss._hurt_touching_players()
	check(p1.hp < hp_before, "standing in its path still gets you hit")



# --- Helpers ------------------------------------------------------------------

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
	# Crashed into a corner, the boss sits under a shelf: a launch lands on the shelf
	# above it, so drop through (hold down) onto its head.
	if is_instance_valid(boss) and boss.state == BarberBot.State.DAZED and rider.is_on_floor() 			and rider.global_position.y < boss.global_position.y - BarberBot.SIZE.y 			and absf(rider.global_position.x - boss.global_position.x) < BarberBot.SIZE.x / 2.0:
		hold(rider, "down", true)
		await _ticks(15)
		hold(rider, "down", false)
	await _ticks(20)
