extends PlayBot
## Bot playthrough of L3 "Wash & Blow-Dry": hair dryers (lift, hover, Hair-copter),
## shampoo showers (wet = no glide / no gel smash) and the growth tonic.
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
		await _pompadour_cant_cross_the_basin_alone()
	finish()


## Dryer lifts P1 alone to the lever; then the Hair-copter takes P2 up the big dryer.
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
	await walk_to(p2, o + 19 * TILE)
	check(p1.global_position.y > 18 * TILE, "R1: P1 dropped off the shelf and went through the gate")
	check(await climb_onto_head(p2, p1), "R1: P2 stands on P1's head in the big dryer")
	check(await _hair_copter(o + 26 * TILE, 8), "R1: Hair-copter: both reach the 11-up exit ledge")
	await enter_exit(room, 1)


## Shower timing for the carry; rinse curtain soaks P2, dryer, then the gel.
func _room_2() -> void:
	var room := level.get_node("Rooms/Room2")
	var o: float = room.global_position.x
	var shower: ShowerHead = room.get_node("TakeOffShower")
	await walk_to(p2, o + 6 * TILE)
	await walk_to(p1, o + 5 * TILE)
	# Wait on the dry start floor until the spray has just stopped, then go.
	await wait_until(func(): return not shower.is_active() and shower._cycle_time() < 0.15, 400)
	walk_to(p2, o + 10.5 * TILE)
	await walk_to(p1, o + 9.6 * TILE)
	await _ticks(2)
	check(not p1.is_wet(), "R2: P1 reaches the take-off ledge dry")
	hold(p1, "skill", true)
	await _ticks(2)
	check(p1.carrying == p2, "R2: P1 grabs P2 on the ledge")
	check(await glide_jump(p1, o + 12 * TILE - 4, o + 22 * TILE, false), "R2: carry over the basin between sprays")
	hold(p1, "skill", false)
	await _ticks(10)
	check(p1.alive and p2.alive, "R2: both land")

	var gel: BreakableWall = room.get_node("GelWall")
	var rinse: ShowerHead = room.get_node("RinseCurtain")
	# The careless way first: walk through while it sprays.
	await wait_until(func(): return rinse.is_active(), 300)
	await walk_to(p2, o + 33 * TILE - 20)
	check(p2.is_wet(), "R2: the rinse shower soaked P2")
	await tap(p2, "skill")
	await _ticks(30)
	check(is_instance_valid(gel) and gel.is_solid(), "R2: soggy pompadour bounces off the gel")
	# Back to the dryer (before the shower), then cross between sprays.
	await walk_to(p2, o + 22.5 * TILE)
	await _ticks(5)
	check(not p2.is_wet(), "R2: the dryer dries P2")
	await walk_to(p2, o + 24 * TILE)
	await wait_until(func(): return not rinse.is_active() and rinse._cycle_time() < 0.15, 400)
	await walk_to(p2, o + 33 * TILE - 20)
	check(not p2.is_wet(), "R2: crossing between sprays keeps P2 dry")
	await tap(p2, "skill")
	await _ticks(30)
	check(not is_instance_valid(room.get_node_or_null("GelWall")), "R2: dry pompadour smashes the gel")
	await enter_exit(room, 2)


## Hair-copter up before the top shower sprays; tonic, dryer, gel, parry the dispenser.
func _room_3() -> void:
	var room := level.get_node("Rooms/Room3")
	var o: float = room.global_position.x
	var shower: ShowerHead = room.get_node("TopShower")
	await walk_to(p1, o + 10.5 * TILE)
	check(await climb_onto_head(p2, p1), "R3: P2 on P1's head in the lift dryer")
	await wait_until(func(): return not shower.is_active() and shower._cycle_time() < 0.15, 400)
	check(await _hair_copter(o + 14 * TILE, 9), "R3: Hair-copter onto the upper ledge before the shower")

	p1.take_hit(1)
	await walk_to(p1, o + 17.5 * TILE)
	await _ticks(5)
	check(p1.hp == p1.max_hp and not is_instance_valid(room.get_node_or_null("Tonic")), "R3: the growth tonic grows P1's hair back")

	await walk_to(p2, o + 24.5 * TILE)
	check(not p2.is_wet(), "R3: the ledge dryer dries P2")
	await walk_to(p2, o + 30 * TILE - 20)
	await tap(p2, "skill")
	await _ticks(30)
	check(not is_instance_valid(room.get_node_or_null("GelWall")), "R3: pompadour smashes the gel")
	var dispenser: ScissorTurret = room.get_node("Dispenser")
	await walk_to(p1, o + 29 * TILE)
	check(await guard_until(p2, func(): return dispenser._jam > 2.0, 900), "R3: P2 parries the dispenser into a jam")
	walk_to(p1, o + 34.5 * TILE)
	await walk_to(p2, o + 35.5 * TILE)
	check(await wait_until(func(): return level.banner.text.ends_with("CLEAR!"), 300), "R3: both at the exit clears L3")


## Counter-check: P2 alone can't jump + dash across room 2's basin.
func _pompadour_cant_cross_the_basin_alone() -> void:
	await load_level(LevelScene, 1)
	var o: float = level.rooms[1].global_position.x
	await walk_to(p2, o + 10 * TILE)
	hold(p2, "right", true)
	hold(p2, "jump", true)
	await wait_until(func(): return p2.global_position.x > o + 12 * TILE, 60)
	await _ticks(6)
	await tap(p2, "skill")
	await wait_until(func(): return not p2.alive or p2.is_on_floor(), 180)
	hold(p2, "right", false)
	hold(p2, "jump", false)
	check(not p2.alive or p2.global_position.x < o + 22 * TILE, "solo: pompadour can't jump-dash over the basin")


## P1 (glider, P2 on her head) rides the dryer up; once high enough P2 hops right onto
## the ledge at ledge_x (top row ledge_row), and P1 glides after. Returns both on top.
func _hair_copter(ledge_x: float, ledge_row: int) -> bool:
	var ledge_top := ledge_row * TILE
	hold(p1, "jump", true)
	hold(p1, "skill", true)
	await wait_until(func(): return p2.global_position.y + Player.HALF_SIZE.y < ledge_top - 1.5 * TILE, 300)
	hold(p2, "right", true)
	hold(p2, "jump", true)
	await wait_until(func(): return p1.global_position.y + Player.HALF_SIZE.y < ledge_top - 0.5 * TILE, 200)
	hold(p1, "right", true)
	# Each lets go once they've landed on the ledge, so nobody runs on into the exit.
	for i in 300:
		for p in [p1, p2]:
			if p.is_on_floor() and p.global_position.x > ledge_x + 16.0:
				for a in ["jump", "skill", "right"]:
					hold(p, a, false)
		if p1.is_on_floor() and p2.is_on_floor() and p1.global_position.x > ledge_x and p2.global_position.x > ledge_x:
			break
		await physics_frame
	for p in [p1, p2]:
		for a in ["jump", "skill", "right"]:
			hold(p, a, false)
	await _ticks(10)
	return p1.alive and p2.alive and p1.global_position.y < ledge_top and p2.global_position.y < ledge_top
