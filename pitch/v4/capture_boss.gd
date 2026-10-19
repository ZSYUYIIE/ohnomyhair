extends "res://tests/test_level_06.gd"
## Mechanic demonstration: stage positions and one projectile, then use real inputs.

func _run() -> void:
	root.size = Vector2i(1280, 720)
	seed(7331)
	await load_level(LevelScene, 3)
	p1.make_invincible(999.0)
	p2.make_invincible(999.0)
	var room := level.rooms[3]
	var boss: BarberBot = room.get_node("BarberBot")
	await wait_until(func(): return boss.state == BarberBot.State.WALK, 300)
	var floor_y: float = 19 * TILE - Player.HALF_SIZE.y
	p1.global_position = Vector2(boss.global_position.x + 150.0, floor_y)
	p2.global_position = p1.global_position + Vector2(0, -2 * Player.HALF_SIZE.y - 4)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	await _ticks(45)
	var s := Scissor.new()
	s.direction = Vector2.RIGHT
	room.add_child(s)
	s.global_position = Vector2(p1.global_position.x - 130.0, p1.global_position.y - 10.0)
	check(await parry_next_scissor(p1, 180), "capture: real parry input reflects the staged scissor")
	check(await wait_until(func(): return boss.state == BarberBot.State.DAZED, 180), "capture: reflected scissors stun the assistant")
	await wait_until(func(): return p1.has_rider(p2), 60)
	await launch_and_stomp(p2, p1, boss)
	check(boss.hp == 9, "capture: launch and stomp reduce the ten-HP assistant to nine")
	await _ticks(90)
	finish()
