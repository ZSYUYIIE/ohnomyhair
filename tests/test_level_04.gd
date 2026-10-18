extends PlayBot
## Plays L4 "Perm Day" (P1 Afro + P2 Pompadour) start to finish with both players' input:
## the spring that beats a launch, the cannonball through gel that sets again, and the
## double return into two bells.
## Run: godot --headless --fixed-fps 60 --path . --script res://tests/test_level_04.gd

const LevelScene := preload("res://scenes/levels/level_04.tscn")


func _run() -> void:
	await load_level(LevelScene)
	check(p1.hair == Player.Hair.AFRO and p2.hair == Player.Hair.POMPADOUR, "Perm Day starts with Afro (P1) and Pompadour (P2)")
	await _room_1()
	if failed == 0:
		await _room_2()
	if failed == 0:
		await _room_3()
	finish()


func _room_1() -> void:
	var room := level.rooms[0]
	var o := room.global_position.x
	# The launch the friends already know comes up 2 tiles short.
	await walk_to(p2, o + 15 * TILE)
	check(await climb_onto_head(p1, p2), "R1: Afro stands on Pompadour's head")
	await tap(p2, "skill")
	var top := 1e9
	for i in 90:
		await physics_frame
		top = minf(top, p1.global_position.y + Player.HALF_SIZE.y)
	check(top > 8 * TILE + 8, "R1: a pompadour launch leaves the afro short of the 11-up shelf")
	await wait_until(func(): return p1.is_on_floor(), 120)
	await walk_to(p1, o + 11 * TILE)
	# The afro's spring does reach.
	await walk_to(p1, o + 15 * TILE)
	check(await climb_onto_head(p2, p1), "R1: Pompadour stands on Afro's head")
	hold(p1, "skill", true)
	await _ticks(40)
	hold(p1, "skill", false)
	check(await wait_until(func(): return p2.is_on_floor() and p2.global_position.y < 8 * TILE, 150), "R1: the afro's spring lands the pompadour on the shelf")
	await walk_to(p2, o + 20.5 * TILE)
	var door: Door = room.get_node("StaffDoor")
	for i in 5:
		if door.is_open:
			break
		await parry_next_scissor(p2, 400)
		await _ticks(40)
	check(door.is_open, "R1: a parried scissor rings the bell and opens the staff door")
	hold(p2, "down", true)
	check(await wait_until(func(): return p2.is_on_floor() and p2.global_position.y > 17 * TILE, 150), "R1: the pompadour drops back down through the shelf")
	hold(p2, "down", false)
	await enter_exit(room, 1)


func _room_2() -> void:
	var room := level.rooms[1]
	var o := room.global_position.x
	var shower: ShowerHead = room.get_node("Rinse")
	var gel: BreakableWall = room.get_node("PermGel")
	await wait_until(func(): return not shower.is_active() and shower._cycle_time() < 0.15, 400)
	await walk_to(p1, o + 7.5 * TILE)
	check(await climb_onto_head(p2, p1), "R2: Pompadour climbs onto Afro between sprays")
	check(not p1.is_wet(), "R2: the afro is still dry")
	hold(p1, "skill", true)
	await _ticks(25)
	hold(p2, "skill", true)
	await _ticks(2)
	hold(p1, "skill", false)
	await wait_until(func(): return not gel.is_solid(), 40)
	var broke := not gel.is_solid()
	hold(p1, "right", true)  # the afro runs for the hole right away
	await wait_until(func(): return p2.is_on_floor() and p2.global_position.x > o + 20 * TILE, 60)
	hold(p2, "skill", false)
	check(broke and p2.global_position.x > o + 20 * TILE, "R2: the cannonball punches the pompadour through the perm-set gel")
	await walk_to(p1, o + 23 * TILE, 240)
	check(p1.global_position.x > o + 21 * TILE, "R2: the afro runs through before the gel sets again")
	await _ticks(200)
	check(gel.is_solid(), "R2: the gel sets again behind them")
	await enter_exit(room, 2)


func _room_3() -> void:
	var room := level.rooms[2]
	var o := room.global_position.x
	var left_bell: HitSwitch = room.get_node("LeftBell")
	var right_bell: HitSwitch = room.get_node("RightBell")
	var door: Door = room.get_node("StaffDoor")
	await walk_to(p1, o + 12.5 * TILE)
	check(p1.global_position.y > 19 * TILE, "R3: the afro waits in the trench")
	await walk_to(p2, o + 16 * TILE)
	# A plain parry sends the scissor back over the trench into the left bell.
	for i in 4:
		if left_bell.pressed:
			break
		await parry_next_scissor(p2, 400)
		await _ticks(60)
	check(left_bell.pressed, "R3: a plain parry rings the left bell")
	# Now the afro holds attack: the next blue scissor is caught...
	hold(p1, "attack", true)
	var caught := false
	for i in 4:
		await parry_next_scissor(p2, 400)
		caught = await wait_until(func(): return is_instance_valid(p1.ability._held), 60)
		if caught:
			break
	check(caught, "R3: the afro catches a blue scissor in the trench")
	# ...turned around, and let go: it flies right, past the friends, into the right bell.
	_face(p1, o + 40 * TILE)
	hold(p1, "attack", false)
	check(await wait_until(func(): return right_bell.pressed, 90), "R3: the returned golden scissor rings the right bell")
	check(door.is_open, "R3: both bells open the staff door")
	await walk_to(p1, o + 20 * TILE)
	var exit_x: float = room.get_node("Exit").global_position.x
	await walk_to(p2, exit_x + 48)
	await walk_to(p1, exit_x + 16)
	check(await wait_until(func(): return level.menu.is_open(), 240) and Progress.is_cleared(3), "Perm Day clear: the results open")
