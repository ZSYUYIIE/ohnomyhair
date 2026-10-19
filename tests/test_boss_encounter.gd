extends PlayBot
## Native collision trials for phase hazards, shelf-to-floor patrols and finite healing.
const Finale := preload("res://scenes/levels/level_06.tscn")

func _run() -> void:
	await load_level(Finale, 3)
	var room := level.rooms[3]
	var boss: BarberBot = room.get_node("BarberBot")
	var arena: WaveArena = room.get_node("Backup")
	var encounter = room.get_node("Encounter")
	boss.process_mode = Node.PROCESS_MODE_DISABLED
	for p in [p1, p2]: p.make_invincible(240)
	check(boss.hp == 10 and boss.phase() == 1, "boss starts with ten health in phase 1")
	check(arena.robots_left() == 0 and encounter.showers.all(func(s): return not s.is_active()), "phase 1 has neither backup nor active showers")
	var phases: Array[int] = []
	boss.phase_changed.connect(func(number): phases.append(number))
	for hit in 3: _hit(boss)
	check(boss.hp == 7 and boss.phase() == 1 and phases.is_empty(), "the first three stomps do not start phase 2 early")
	_hit(boss)
	check(boss.hp == 6 and boss.phase() == 2 and phases == [2], "health 6 triggers phase 2 exactly once")
	check(arena._warning.size() == 3 and arena.robots_left() == 0, "all three backup slots warn before robots fall")
	check(encounter.showers.all(func(s): return not s.is_active()), "phase change gives a grace period before water starts")
	await _ticks(56)
	check(arena.robots_left() == 3, "three phase-2 reinforcements arrive after the warning")
	var left: ClipperBot = arena.robots[0]
	var right: ClipperBot = arena.robots[-1]
	check(await wait_until(func(): return left.is_on_floor() and left.position.y < 550, 90), "left minion physically lands on the one-way shelf")
	check(await wait_until(func(): return right.is_on_floor() and right.position.y < 550, 20), "right minion physically lands on its shelf")
	check(await wait_until(func(): return left.is_on_floor() and left.position.y >= 600, 180), "minion walks off its shelf and lands on the ground floor")
	check(await wait_until(func(): return left.position.x > 600, 360), "reinforcement crosses the middle instead of staying near its spawn")
	encounter._supply_wait = 999
	p1.global_position = left.global_position + Vector2(0, -22)
	p1.hp = 3
	p1._invincible = 0
	await _ticks(2)
	check(p1.hp == 2, "a roaming minion damages a player through real contact")
	p1.make_invincible(240)
	p1.hp = 3
	p1.global_position = room.global_position + Vector2(400, 586)
	p2.global_position = room.global_position + Vector2(320, 586)
	p2.velocity = Vector2.ZERO
	check(await wait_until(func(): return p2.is_wet(), 400), "phase-2 shower physically soaks a player in its lane")
	check(p2.hp == 3, "water changes hair abilities without dealing direct damage")
	await walk_to(p2, room.global_position.x + 624, 180, false)
	await _ticks(5)
	check(not p2.is_wet() and encounter.dryer in p2.updrafts, "walking to the central dryer restores wet hair before natural drying")
	var never_both := true
	var saw_warning := false
	for frame in 360:
		never_both = never_both and encounter.showers.filter(func(s): return s.is_active()).size() <= 1
		saw_warning = saw_warning or encounter.showers.any(func(s): return s._is_warning())
		await physics_frame
	check(never_both and saw_warning, "showers warn and alternate with an open lane at all times")
	boss.daze(4)
	await _ticks(2)
	check(encounter.showers.all(func(s): return not s.is_active()), "water rests during the co-op stomp window")
	boss._enter(BarberBot.State.WALK)
	for hit in 2: _hit(boss)
	check(boss.hp == 4 and boss.phase() == 2 and phases == [2], "phase 2 lasts down to four health")
	_hit(boss)
	check(boss.hp == 3 and boss.phase() == 3 and phases == [2, 3] and boss.shots == 5, "health 3 starts the furious phase exactly once")
	check(encounter.showers[0].off_time == 3 and arena.wave == 1, "phase 3 speeds up the water and requests the larger wave")
	await _ticks(60)
	check(arena.robots_left() == 4, "phase-3 backup tops up surviving minions to the cap of four")
	for request in 5: arena.reinforce()
	await _ticks(60)
	check(arena.robots_left() == 4 and arena._warning.is_empty(), "repeated calls cannot exceed the living-plus-pending minion cap")
	for bot in arena.robots: bot.take_hit(1)
	await _ticks(2)
	encounter._refill = 0
	await _ticks(60)
	check(arena.robots_left() == 4, "clearing the backup allows a later warned refill in the same phase")
	check(encounter.supplies_spawned == 0, "full-health players do not generate free potions")
	p1.hp = 2
	encounter._supply_wait = 0
	await _ticks(2)
	check(encounter.tonics.size() == 1 and encounter.supplies_spawned == 1, "a wounded team receives one phase reward tonic")
	var tonic: GrowthTonic = encounter.tonics[0]
	p2.global_position = tonic.global_position
	await _ticks(4)
	check(is_instance_valid(tonic), "a full-health friend leaves the tonic for the hurt player")
	p1.global_position = tonic.global_position
	await _ticks(4)
	check(p1.hp == 3 and not is_instance_valid(tonic), "collecting a tonic restores exactly one heart and consumes it")
	p1.hp = 1
	await _ticks(120)
	check(encounter.tonics.is_empty(), "critical health cannot bypass the potion cooldown")
	p1.global_position = room.global_position + Vector2(400, 586)
	await _ticks(900)
	check(encounter.supplies_spawned == 2 and encounter.tonics.size() == 1, "critical health gets a single emergency tonic after cooldown")
	# Accelerate the supply clock, never the spawn count, to check the finite reserve.
	for request in 5:
		for bottle in encounter.tonics:
			if is_instance_valid(bottle): bottle.queue_free()
		await _ticks(2)
		encounter._supply_wait = 0
		await _ticks(2)
	check(encounter.supplies_spawned == 4, "the encounter has only four healing supplies even when players stall")
	for hit in 3: _hit(boss)
	await _ticks(3)
	check(room.get_node("BossDoor").is_open and arena.robots_left() == 0 and arena._warning.is_empty(), "victory opens the door and scraps living/pending reinforcements")
	check(encounter.showers.all(func(s): return not s.is_active()) and encounter._stopped, "victory shuts off the water and supply controller")
	level.restart_room()
	await _ticks(5)
	var fresh_boss: BarberBot = level.rooms[3].get_node("BarberBot")
	var fresh_encounter = level.rooms[3].get_node("Encounter")
	check(fresh_boss.hp == 10 and fresh_encounter.supplies_spawned == 0 and not fresh_encounter._stopped, "room retry restores ten boss health and resets the finite supplies")
	finish()

func _hit(boss: BarberBot) -> void:
	boss._stomped_by(p2)
	# Direct unit hits should not stack real-time hit-stop timers in fixed-fps trials.
	Engine.time_scale = 1.0
