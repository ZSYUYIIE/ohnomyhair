extends PlayBot
## Bot playthrough of L3 "Wash & Blow-Dry": hair dryers (lift, carry lift), shampoo
## showers (wet = no glide / no gel smash, dries by itself or in a dryer).
## Counter-checks: pompadour alone can't cross either dye pool (her best jump + dash),
## wet hair dries without a restart, and a carry caught by a shower falls.
## Run: godot --headless --fixed-fps 60 --path . --script res://tests/test_level_03.gd

const LevelScene := preload("res://scenes/levels/level_03.tscn")


func _run() -> void:
	await load_level(LevelScene)
	await _room_1()
	if failed == 0:
		await _room_2()
	if failed == 0:
		await _room_3()
	begin_counter_checks()  # the rest are counter-checks that fall in the dye on purpose
	await _soaked_hair_dries_by_itself()
	await _pompadour_cant_cross_alone(1, 10, 13, 30)
	await _pompadour_cant_cross_alone(2, 7, 16, 34)
	await _shower_drops_a_carry_mid_flight()
	finish()


## Dryer lifts P1 alone to the lever; then the big dryer lifts P1 carrying P2.
func _room_1() -> void:
	var room := level.get_node("Rooms/Room1")
	var o: float = room.global_position.x
	await walk_to(p1, o + 6.5 * TILE)
	hold(p1, "jump", true)
	hold(p1, "skill", true)
	check(await wait_until(func(): return p1.global_position.y < 8 * TILE, 240), "R1: the dryer lifts gliding twin-tails")
	# Steer right over the shelf (x=9-13), then let go of the direction and drift down onto it.
	hold(p1, "right", true)
	await wait_until(func(): return p1.global_position.x > o + 10.5 * TILE, 120)
	hold(p1, "right", false)
	await wait_until(func(): return p1.is_on_floor(), 180)
	for a in ["jump", "skill"]:
		hold(p1, a, false)
	check(p1.global_position.y < 9 * TILE, "R1: she glides onto the lever shelf")
	await walk_to(p1, o + 11.5 * TILE)
	await tap(p1, "skill")
	await _ticks(45)
	check(room.get_node("GateLever").is_on, "R1: the lever raises the gate")

	await walk_to(p1, o + 22.5 * TILE)
	await walk_to(p2, o + 21.6 * TILE)
	check(p1.global_position.y > 18 * TILE, "R1: P1 dropped off the shelf and went through the gate")
	check(await _carry_up(o + 26 * TILE, 8), "R1: P1 carries P2 up the big dryer to the 11-up exit ledge")
	if level.room_index == 0:
		await enter_exit(room, 1)
	else:
		await wait_until(func(): return not level._busy, 120)


## Shower timing on the counter for the carry; rinse curtain soaks P2, dryer, then the gel.
func _room_2() -> void:
	var room := level.get_node("Rooms/Room2")
	var o: float = room.global_position.x
	var shower: ShowerHead = room.get_node("TakeOffShower")
	# P2 waits at the counter's far end (getting wet doesn't matter to the one who hangs);
	# P1 waits on the top stair, outside the spray, and hops up when it stops.
	await walk_to(p2, o + 12.4 * TILE)
	await walk_to(p1, o + 8.6 * TILE)
	await wait_until(func(): return not shower.is_active() and shower._cycle_time() < 0.15, 400)
	await walk_to(p1, o + 10.8 * TILE)
	check(not p1.is_wet(), "R2: P1 steps onto the counter between sprays, dry")
	check(await grab(p1, p2), "R2: P1 grabs P2 on the counter")
	check(await glide_jump(p1, o + 13 * TILE - 4, o + 30 * TILE, false), "R2: carry over the 17-wide dye between sprays")
	hold(p1, "skill", false)
	await _ticks(10)
	check(p1.alive and p2.alive, "R2: both land")

	var gel: BreakableWall = room.get_node("GelWall")
	var rinse: ShowerHead = room.get_node("RinseCurtain")
	# The careless way first: walk through while it sprays.
	await wait_until(func(): return rinse.is_active(), 300)
	await walk_to(p2, o + 35 * TILE - 20)
	check(p2.is_wet(), "R2: the rinse shower soaked P2")
	_face(p2, o + 40 * TILE)  # dash at the gel, not back toward the dye
	await tap(p2, "skill")
	await _ticks(30)
	check(is_instance_valid(gel) and gel.is_solid(), "R2: soggy pompadour bounces off the gel")
	# Back to the dryer (before the shower), then cross between sprays.
	await walk_to(p2, o + 31 * TILE)
	await _ticks(5)
	check(not p2.is_wet(), "R2: the dryer dries P2 at once")
	await wait_until(func(): return not rinse.is_active() and rinse._cycle_time() < 0.15, 400)
	await walk_to(p2, o + 35 * TILE - 20)
	check(not p2.is_wet(), "R2: crossing between sprays keeps P2 dry")
	_face(p2, o + 40 * TILE)
	await tap(p2, "skill")
	await _ticks(30)
	check(not is_instance_valid(room.get_node_or_null("GelWall")), "R2: dry pompadour smashes the gel")
	await enter_exit(room, 2)


## Up the dryer through the column shower, then over the pool under the pool shower.
func _room_3() -> void:
	var room := level.get_node("Rooms/Room3")
	var o: float = room.global_position.x
	await walk_to(p2, o + 5.0 * TILE)
	await walk_to(p1, o + 6.0 * TILE)
	# Go whenever: if the spray catches them they drop back into the warm air, dry off
	# under it, and rise again once it stops ("wait for a gap" happens by itself).
	check(await _carry_up(o + 9.5 * TILE, 7, 900), "R3: P1 carries P2 up through the column shower onto the ledge")

	var pool_shower: ShowerHead = room.get_node("PoolShower")
	await walk_to(p2, o + 14.4 * TILE)
	await walk_to(p1, o + 13.6 * TILE)
	check(await grab(p1, p2), "R3: P1 grabs P2 at the ledge's edge")
	await wait_until(func(): return not pool_shower.is_active() and pool_shower._cycle_time() < 0.15, 400)
	var landed := await glide_jump(p1, o + 16 * TILE - 4, o + 34 * TILE, false)
	# Gliding on into the exit door clears the room mid-air, which is a win too.
	var cleared_in_flight: bool = level.banner.text.contains("CLEAR!")
	check(landed or cleared_in_flight, "R3: carry over the 18-wide dye right after the spray stops")
	hold(p1, "skill", false)
	await _ticks(10)
	check(p1.alive and p2.alive, "R3: both make it across")
	if not cleared_in_flight:
		var exit_x: float = room.get_node("Exit").global_position.x
		walk_to(p2, exit_x + 48)
		await walk_to(p1, exit_x + 16)
	check(await wait_until(func(): return level.banner.text.contains("CLEAR!"), 300), "R3: both at the exit clears L3")


## No restart needed: P1 soaked on R2's counter dries by herself a few seconds later.
func _soaked_hair_dries_by_itself() -> void:
	await load_level(LevelScene, 1)
	var o: float = level.rooms[1].global_position.x
	var shower: ShowerHead = level.rooms[1].get_node("TakeOffShower")
	await walk_to(p1, o + 11.5 * TILE)
	await wait_until(func(): return shower.is_active(), 300)
	await _ticks(5)
	check(p1.is_wet(), "wet: the counter shower soaks P1")
	hold(p1, "skill", true)
	hold(p1, "jump", true)
	await _ticks(20)
	check(not p1.ability.is_gliding(), "wet: soaked twin-tails can't glide")
	hold(p1, "skill", false)
	hold(p1, "jump", false)
	await walk_to(p1, o + 7 * TILE)
	check(await wait_until(func(): return not p1.is_wet(), int(4.5 * 60)), "wet: off the counter, her hair dries by itself within 4.5 s")


## Counter-check for room index `room`: P2 alone, from the take-off ledge whose edge is at
## `edge_col` (top row `top_row`), tries the best measured jump-dash (ground dash to the
## lip, jump as it ends, one air dash later); she must not reach the landing at `land_col`.
func _pompadour_cant_cross_alone(room: int, top_row: int, edge_col: int, land_col: int) -> void:
	var best := 0.0
	for air_dash_at in [20, 26, 30, 35, 40]:
		await load_level(LevelScene, room)
		var o: float = level.rooms[room].global_position.x
		p2.global_position = Vector2(o + (edge_col - 3) * TILE, top_row * TILE - Player.HALF_SIZE.y)
		p2.velocity = Vector2.ZERO
		await _ticks(5)
		hold(p2, "right", true)
		await wait_until(func(): return p2.global_position.x + Player.HALF_SIZE.x >= o + edge_col * TILE - 120.0, 120)
		await tap(p2, "skill")
		await wait_until(func(): return p2.ability._dash_left <= 0.0, 30)
		hold(p2, "jump", true)
		await _ticks(air_dash_at)
		await tap(p2, "skill")
		await wait_until(func(): return not p2.alive or p2.is_on_floor(), 240)
		for a in ["right", "jump"]:
			hold(p2, a, false)
		best = maxf(best, p2.global_position.x - o if p2.alive else 0.0)
	check(best < land_col * TILE, "solo (room %d): pompadour's best jump + air dash falls short of the landing (best x=%.1f tiles, landing %d)" % [room + 1, best / TILE, land_col])


## R3's pool shower turns on while the carry is under it: wet tails stop gliding, both fall.
func _shower_drops_a_carry_mid_flight() -> void:
	await load_level(LevelScene, 2)
	var o: float = level.rooms[2].global_position.x
	var pool_shower: ShowerHead = level.rooms[2].get_node("PoolShower")
	p1.global_position = Vector2(o + 13.6 * TILE, 7 * TILE - Player.HALF_SIZE.y)
	p2.global_position = Vector2(o + 14.4 * TILE, 7 * TILE - Player.HALF_SIZE.y)
	await _ticks(5)
	hold(p1, "skill", true)
	await _ticks(2)
	# Take off 0.4 s before the spray starts: it's pouring by the time they get there.
	await wait_until(func(): return absf(pool_shower._cycle_time() - (pool_shower.off_time - 0.4)) < 0.02, 400)
	await glide_jump(p1, o + 16 * TILE - 4, o + 34 * TILE, false)
	hold(p1, "skill", false)
	check(not p1.alive or not p2.alive, "flying into the running shower soaks P1 and drops the carry into the dye")


## Carry P2 (standing beside P1) up the dryer P1 is in, then glide right onto the ledge
## at ledge_x (top row ledge_row). Returns true once both stand on it.
func _carry_up(ledge_x: float, ledge_row: int, max_ticks := 600) -> bool:
	var ledge_top := ledge_row * TILE
	var room_at_start := level.room_index
	hold(p1, "skill", true)
	await _ticks(2)
	if p1.carrying != p2:
		return false
	hold(p1, "jump", true)
	# Rise until P1's feet are well above the ledge (dropping back under a shower is fine).
	var high := await wait_until(func(): return p1.global_position.y + Player.HALF_SIZE.y < ledge_top - 1.5 * TILE, max_ticks)
	hold(p1, "right", true)
	for i in 300:
		if p1.is_on_floor() and p1.global_position.x > ledge_x + 16.0:
			break
		if level.room_index != room_at_start:
			break
		await physics_frame
	for a in ["jump", "skill", "right"]:
		hold(p1, a, false)
	await _ticks(10)
	if level.room_index != room_at_start:
		return true
	return high and p1.alive and p2.alive and p1.global_position.y < ledge_top and p2.global_position.y < ledge_top
