extends PlayBot
## Physical route for every allowed finale pair: use a real launch
## to reach the corner, bait a real wall crash, and drop onto the assistant's knob.
## Fixed starting positions and temporary immunity isolate route geometry from
## survival AI. No injected daze, projectile or direct stomp callback is used.
const Finale := preload("res://scenes/levels/level_06.tscn")

func _run() -> void:
	for pair in StyleRules.pairs(PackedInt32Array([0, 1])):
		await _pair_route(pair)
	finish()

func _pair_route(pair: Array) -> void:
	for action in InputMap.get_actions(): Input.action_release(action)
	await load_level(Finale, 3)
	var room := level.rooms[3]
	var origin := room.global_position.x
	var label := "%s + %s" % [StyleRules.hair_name(pair[0]), StyleRules.hair_name(pair[1])]
	# The scripted chair / boss scissors can produce either distinct pair.
	p1.set_hair(pair[0])
	p2.set_hair(pair[1])
	check(not room.has_node("StylingStation"), label + ": boss arena has no spawn-point chair")
	var boss: BarberBot = room.get_node("BarberBot")
	boss.process_mode = Node.PROCESS_MODE_DISABLED
	boss.position = Vector2(500, 608)
	boss.velocity = Vector2.ZERO
	for p in [p1, p2]: p.make_invincible(60)
	var base := p1 if p1.hair == Player.Hair.POMPADOUR else p2
	var actor := base.teammate()
	base.respawn_at(Vector2(origin + 80, 586))
	actor.respawn_at(Vector2(origin + 80, 542))
	await _ticks(10)
	await tap(base, "skill")
	await _ticks(10)
	var reached := await wait_until(func(): return actor.is_on_floor() and actor.global_position.y < 400, 180)
	check(reached, label + ": reaches the high corner using its equipped ability")
	if not reached: return
	# Keep the other friend on the left to bait the assistant towards the corner wall.
	base.respawn_at(Vector2(origin + 250, 586))
	for p in [p1, p2]: p.make_invincible(60)
	boss.process_mode = Node.PROCESS_MODE_INHERIT
	check(await wait_until(func(): return boss.state == BarberBot.State.DAZED, 300), label + ": charge crashes into the wall without a parry")
	var hp_before := boss.hp
	hold(actor, "down", true)
	check(await wait_until(func(): return boss.hp < hp_before, 100), label + ": dropping from the corner physically stomps the dazed boss")
	hold(actor, "down", false)
