extends PlayBot
## Physical route for every allowed finale pair: use a real launch, spring or hook
## to reach the corner, bait a real wall crash, and drop onto Tony's knob.
## Fixed starting positions and temporary immunity isolate route geometry from
## survival AI. No injected daze, projectile or direct stomp callback is used.
const Finale := preload("res://scenes/levels/level_06.tscn")

func _run() -> void:
	for pair in StyleRules.pairs(PackedInt32Array([0, 1, 2, 3])):
		await _pair_route(pair)
	finish()

func _pair_route(pair: Array) -> void:
	for action in InputMap.get_actions(): Input.action_release(action)
	await load_level(Finale, 3)
	var room := level.rooms[3]
	var origin := room.global_position.x
	var label := "%s + %s" % [StyleRules.hair_name(pair[0]), StyleRules.hair_name(pair[1])]
	level.open_styling(room.get_node("StylingStation"))
	level.styling_menu.choose(0, pair[0])
	level.styling_menu.choose(1, pair[1])
	level.styling_menu.commit()
	check(p1.hair == pair[0] and p2.hair == pair[1], label + ": chair applies the distinct pair")
	var boss: BarberBot = room.get_node("BarberBot")
	boss.process_mode = Node.PROCESS_MODE_DISABLED
	boss.position = Vector2(500, 608)
	boss.velocity = Vector2.ZERO
	for p in [p1, p2]: p.make_invincible(60)
	var actor: Player
	var base: Player
	if Player.Hair.LONG_STRAIGHT in pair:
		actor = p1 if p1.hair == Player.Hair.LONG_STRAIGHT else p2
		base = actor.teammate()
		actor.respawn_at(Vector2(origin + 130, 586))
		base.respawn_at(Vector2(origin + 250, 586))
		await _ticks(5)
		hold(actor, "jump", true)
		await _ticks(9)
		hold(actor, "skill", true)
		await wait_until(func(): return actor.global_position.y < 360, 60)
		hold(actor, "skill", false)
		hold(actor, "jump", false)
		hold(actor, "left", true)
		await wait_until(func(): return actor.global_position.x < origin + 95, 60)
		hold(actor, "left", false)
	else:
		var support := Player.Hair.POMPADOUR if Player.Hair.POMPADOUR in pair else Player.Hair.AFRO
		base = p1 if p1.hair == support else p2
		actor = base.teammate()
		base.respawn_at(Vector2(origin + 80, 586))
		actor.respawn_at(Vector2(origin + 80, 542))
		await _ticks(10)
		if support == Player.Hair.AFRO:
			hold(base, "skill", true)
			await _ticks(40)
			hold(base, "skill", false)
		else:
			await tap(base, "skill")
	await _ticks(10)
	var reached := await wait_until(func(): return actor.is_on_floor() and actor.global_position.y < 400, 180)
	check(reached, label + ": reaches the high corner using its equipped ability")
	if not reached: return
	# Keep the other friend on the left to bait Tony towards the corner wall.
	base.respawn_at(Vector2(origin + 250, 586))
	for p in [p1, p2]: p.make_invincible(60)
	boss.process_mode = Node.PROCESS_MODE_INHERIT
	check(await wait_until(func(): return boss.state == BarberBot.State.DAZED, 300), label + ": charge crashes into the wall without a parry")
	var hp_before := boss.hp
	hold(actor, "down", true)
	check(await wait_until(func(): return boss.hp < hp_before, 100), label + ": dropping from the corner physically stomps the dazed boss")
	hold(actor, "down", false)
