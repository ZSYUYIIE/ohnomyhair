extends PlayBot
## End-to-end traversal of the authored expansion, using both players' inputs.
const Lab := preload("res://scenes/levels/style_lab.tscn")

func _run() -> void:
	await load_level(Lab)
	await _cannonball_room()
	if failed == 0: await _rope_room()
	if failed == 0: await _boss_room()
	finish()

func _cannonball_room() -> void:
	var room := level.rooms[0]
	await walk_to(p1, 600)
	check(not p1.is_wet(), "studio: Afro arrives at the spring spot dry")
	check(await climb_onto_head(p2, p1), "studio: Pompadour jumps onto Afro's head")
	hold(p1, "skill", true)
	await _ticks(40)
	hold(p2, "skill", true)
	await _ticks(3)
	hold(p1, "skill", false)
	await _ticks(35)
	hold(p2, "skill", false)
	check(not is_instance_valid(room.get_node_or_null("ReinforcedGel")) and p2.global_position.x > 800, "studio: the co-op cannonball opens the full-height gel curtain")
	await enter_exit(room, 1)
	check(p1.hair == Player.Hair.LONG_STRAIGHT and p2.hair == Player.Hair.TWIN_TAILS, "crossing introduces the rope/glide pair")

func _rope_room() -> void:
	var room := level.rooms[1]
	var x := room.global_position.x
	await walk_to(p1, x + 280)
	hold(p1, "jump", true)
	await _ticks(9)
	hold(p1, "skill", true)
	await _ticks(35)
	hold(p1, "jump", false)
	hold(p1, "skill", false)
	await _ticks(25)
	check(p1.is_on_floor() and p1.global_position.y < 330, "crossing: Long Straight hooks onto the high ledge")
	await walk_to(p1, x + 330)
	_face(p1, x + 900)
	hold(p1, "skill", true)
	await _ticks(3)
	await walk_to(p2, x + 300)
	hold(p2, "right", true)
	hold(p2, "jump", true)
	await wait_until(func(): return p2.global_position.x > x + 355, 40)
	hold(p2, "right", false)
	check(await wait_until(func(): return p2.rope_provider == p1, 40), "crossing: Twin-Tails grabs the hair rope over the gap")
	check(await wait_until(func(): return p2.global_position.y < p1.global_position.y - 35, 150), "crossing: Twin-Tails climbs above the high ledge")
	hold(p2, "jump", false)
	hold(p2, "right", true)
	hold(p2, "skill", true)
	check(await wait_until(func(): return p2.global_position.x > x + 890 and p2.is_on_floor(), 240), "crossing: rope release plus glide reaches the far bank")
	hold(p2, "right", false)
	hold(p2, "skill", false)
	hold(p1, "skill", false)
	await walk_to(p2, x + 1008)
	await tap(p2, "skill")
	check(room.get_node("BridgeLever").is_on, "crossing: Twin-Tails lowers the return bridge")
	await _ticks(90)
	await walk_to(p1, x + 1120)
	check(p1.alive and p1.global_position.x > x + 1000, "crossing: the bridge brings the rope provider safely across")
	await enter_exit(room, 2)

func _boss_room() -> void:
	var room := level.rooms[2]
	var boss: BarberBot = room.get_node("BarberBot")
	check(p1.hair == Player.Hair.AFRO and p2.hair == Player.Hair.POMPADOUR, "makeover arena starts with Afro and Pompadour")
	# The combat route is shared with campaign L4; exercise the new projectile contract here.
	boss._fire()
	await _ticks(2)
	check(get_nodes_in_group("scissors").any(func(s): return s.restyles), "makeover: Tony fires haircut-changing scissors")
	# Test the authored victory wiring independently of timing already covered in L4.
	for i in 3:
		boss._stomped_by(p2)
	check(room.get_node("BossDoor").is_open, "makeover: defeating Tony opens the lab exit")
	await _ticks(60)
	var x := room.global_position.x
	await walk_to(p2, x + 1210)
	await walk_to(p1, x + 1190)
	check(await wait_until(func(): return level.menu.is_open(), 240), "both friends reach the Style Lab results")
	check(not Progress.is_cleared(0) and not Progress.is_unlocked(3), "Style Lab cannot mark campaign chapters cleared or unlock chapter 4")
