extends PlayBot
## Plays L5 "Extensions" (P1 Twin-Tails + P2 Long Straight) start to finish with both
## players' input: ring, rope and lasso; the Hair-copter with a new rider and a carry from
## 13 up; then the exam under a shower.
## Run: godot --headless --fixed-fps 60 --path . --script res://tests/test_level_05.gd

const LevelScene := preload("res://scenes/levels/level_05.tscn")


func _run() -> void:
	await load_level(LevelScene)
	check(p1.hair == Player.Hair.TWIN_TAILS and p2.hair == Player.Hair.LONG_STRAIGHT, "Extensions starts with Twin-Tails (P1) and Long Straight (P2)")
	await _room_1()
	if failed == 0:
		await _room_2()
	if failed == 0:
		await _room_3()
	finish()


## Long Straight jumps at `from_x` and hooks the nearest ring; true once standing above `top_y`.
func _hook_up(from_x: float, top_y: float) -> bool:
	await walk_to(p2, from_x)
	hold(p2, "jump", true)
	await _ticks(9)
	hold(p2, "skill", true)
	await _ticks(35)
	hold(p2, "jump", false)
	hold(p2, "skill", false)
	await _ticks(25)
	return p2.is_on_floor() and p2.global_position.y < top_y


## Long Straight stands at `edge_x` facing left and lowers the rope; twin-tails climbs it
## and steps right onto the ledge. True once twin-tails stands above `top_y`.
func _rope_up(edge_x: float, top_y: float) -> bool:
	await walk_to(p2, edge_x)
	_face(p2, edge_x - 400)
	hold(p2, "skill", true)
	await _ticks(3)
	var rope_x: float = p2.ability.rope_x()
	await walk_to(p1, rope_x - 6)
	hold(p1, "jump", true)
	var grabbed := await wait_until(func(): return p1.rope_provider == p2, 40)
	await wait_until(func(): return p1.rope_provider == null, 200)
	hold(p1, "jump", false)
	# Popped off the top of the rope: step just onto the ledge, not across it.
	hold(p1, "right", true)
	await wait_until(func(): return p1.global_position.x > rope_x + 30, 60)
	hold(p1, "right", false)
	await wait_until(func(): return p1.is_on_floor(), 90)
	hold(p2, "skill", false)
	await _ticks(5)
	return grabbed and p1.is_on_floor() and p1.global_position.y < top_y


## Twin-tails grabs Long Straight beside her and flies right off the edge at take_off_x,
## with Long Straight lassoing `bot` on the way down. True once both stand past land_x.
func _carry_over(take_off_x: float, land_x: float, bot: ClipperBot) -> bool:
	await walk_to(p1, take_off_x - 80)
	await walk_to(p2, take_off_x - 50)
	_face(p2, take_off_x + 400)
	hold(p1, "skill", true)
	await _ticks(2)
	var grabbed := p1.carrying == p2
	hold(p1, "right", true)
	var jumped := false
	var lassoed := false
	for i in 500:
		await physics_frame
		if not jumped and p1.global_position.x >= take_off_x:
			hold(p1, "jump", true)
			jumped = true
		if jumped and not lassoed and is_instance_valid(bot) and absf(bot.global_position.x - p2.global_position.x) < 180:
			_face(p2, bot.global_position.x)
			await tap(p2, "attack")
			lassoed = true
		if jumped and p1.is_on_floor() and p1.global_position.x > land_x:
			break
	hold(p1, "right", false)
	hold(p1, "jump", false)
	hold(p1, "skill", false)
	await _ticks(10)
	return grabbed and p1.alive and p2.alive and p1.global_position.x > land_x and p2.global_position.x > land_x - 32


func _room_1() -> void:
	var room := level.rooms[0]
	var o := room.global_position.x
	check(await _hook_up(o + 18 * TILE, 10 * TILE), "R1: Long Straight hooks the ring onto the bar")
	check(await _rope_up(o + 19.6 * TILE, 10 * TILE), "R1: twin-tails climbs the hair rope up the bar")
	await walk_to(p2, o + 28.5 * TILE)
	_face(p2, o + 40 * TILE)
	await tap(p2, "attack")
	check(room.get_node("GateLever").is_on, "R1: Long Straight lassos the lever high on the wall")
	await _ticks(40)
	await enter_exit(room, 1)


func _room_2() -> void:
	var room := level.rooms[1]
	var o := room.global_position.x
	await walk_to(p1, o + 4 * TILE)
	check(await climb_onto_head(p2, p1), "R2: Long Straight stands on twin-tails' head in the dryer")
	hold(p1, "jump", true)
	hold(p1, "skill", true)
	await wait_until(func(): return p2.global_position.y + Player.HALF_SIZE.y < 4.5 * TILE, 300)
	hold(p2, "right", true)
	hold(p2, "jump", true)
	await wait_until(func(): return p1.global_position.y + Player.HALF_SIZE.y < 5.5 * TILE, 200)
	hold(p1, "right", true)
	for i in 300:
		for p in [p1, p2]:
			# The tower top is only 6 tiles wide: stop gliding once over it.
			if p.global_position.x > o + 7.5 * TILE:
				for a in ["jump", "skill", "right"]:
					hold(p, a, false)
		if p1.is_on_floor() and p2.is_on_floor() and p1.global_position.x > o + 6 * TILE and p2.global_position.x > o + 6 * TILE:
			break
		await physics_frame
	for p in [p1, p2]:
		for a in ["jump", "skill", "right"]:
			hold(p, a, false)
	await _ticks(10)
	check(p1.global_position.y < 6 * TILE and p2.global_position.y < 6 * TILE, "R2: the Hair-copter lifts both onto the 13-up tower")
	check(await _carry_over(o + 11.5 * TILE, o + 33 * TILE, room.get_node("ClipperBot")), "R2: twin-tails carries Long Straight over 21 tiles of dye")
	await enter_exit(room, 2)


func _room_3() -> void:
	var room := level.rooms[2]
	var o := room.global_position.x
	var shower: ShowerHead = room.get_node("LedgeShower")
	check(await _hook_up(o + 5 * TILE, 10 * TILE), "R3: Long Straight hooks the ring onto the ledge")
	# The ledge's left end is dry: climb there, then take off between sprays.
	check(await _rope_up(o + 6.5 * TILE, 10 * TILE), "R3: twin-tails climbs the rope at the dry end of the ledge")
	check(not p1.is_wet(), "R3: twin-tails is still dry")
	await wait_until(func(): return not shower.is_active() and shower._cycle_time() < 0.15, 600)
	check(await _carry_over(o + 10.6 * TILE, o + 29.5 * TILE, room.get_node("ClipperBot")), "R3: twin-tails carries Long Straight over 18 tiles of dye between sprays")
	await walk_to(p2, o + 30.5 * TILE)
	_face(p2, o + 40 * TILE)
	await tap(p2, "attack")
	check(room.get_node("GateLever").is_on, "R3: Long Straight lassos the gate lever")
	await _ticks(40)
	var exit_x: float = room.get_node("Exit").global_position.x
	await walk_to(p2, exit_x + 48)
	await walk_to(p1, exit_x + 16)
	check(await wait_until(func(): return level.menu.is_open(), 240) and Progress.is_cleared(4), "Extensions clear: the results open")
