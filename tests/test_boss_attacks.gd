extends PlayBot
## Actual projectiles test warning, aim lock, shelf pressure and an escape route.
const Finale := preload("res://scenes/levels/level_06.tscn")
const Rain := preload("res://scenes/enemies/boss_scissor_rain.gd")

func _run() -> void:
	await load_level(Finale, 3)
	var room := level.rooms[3]
	var boss: BarberBot = room.get_node("BarberBot")
	boss.process_mode = Node.PROCESS_MODE_DISABLED
	for player in [p1, p2]: player.make_invincible(30)
	boss._enter(BarberBot.State.SHOOT)
	boss._aim_target = p1
	boss._t = 0.4
	p1.global_position += Vector2(0, -150)
	boss._shoot()
	check(boss._aim_point.is_equal_approx(p1.global_position), "burst follows an elevated player during the warning")
	boss._t = 0.19
	boss._shoot()
	var locked := boss._aim_point
	p1.global_position += Vector2(130, 0)
	boss._shoot()
	check(boss._aim_locked and boss._aim_point == locked, "aim freezes before release, leaving a dodge window")
	var before := get_nodes_in_group("scissors").size()
	boss._t = 0
	boss._shoot()
	await _ticks(2)
	var projectiles := get_nodes_in_group("scissors")
	check(projectiles.size() == before + 1, "one aimed scissor is released per warning")
	var shot: Scissor = projectiles[-1]
	var direction := shot.direction
	check(direction.y < -0.1, "aimed burst can shoot upward towards a shelf")
	p1.global_position += Vector2(200, 80)
	await _ticks(8)
	check(is_instance_valid(shot) and shot.direction == direction, "released scissors fly straight and never chase a dodge")
	if is_instance_valid(shot):
		shot.deflect()
		check(shot.deflected and shot.direction.is_equal_approx(-direction), "angled shots remain parryable")
	boss.velocity.x = 0
	boss.facing = 1
	boss._charge(1.0 / 60)
	check(boss.velocity.x > 0 and boss.velocity.x < boss.charge_speed, "charge accelerates into the run instead of instantly sliding at full speed")
	boss.daze(2)
	check(boss.velocity.x == 0, "a crash immediately stops the boss during the counterattack window")
	await _shelf_trial(false)
	await _shelf_trial(true)
	await _shelf_trial(false, true)
	await _shelf_trial(true, true)
	await load_level(Finale, 3)
	room = level.rooms[3]
	boss = room.get_node("BarberBot")
	boss.process_mode = Node.PROCESS_MODE_DISABLED
	boss._enter(BarberBot.State.RAIN)
	boss.daze(3)
	await _ticks(100)
	check(get_nodes_in_group("scissors").is_empty(), "dazing the boss cancels pending overhead snips")
	finish()

func _shelf_trial(dodge: bool, furious := false) -> void:
	await load_level(Finale, 3)
	var room := level.rooms[3]
	var boss: BarberBot = room.get_node("BarberBot")
	boss.process_mode = Node.PROCESS_MODE_DISABLED
	if furious: boss.hp = 1
	# The real left platform, not a synthetic collision or injected hit callback.
	p1.respawn_at(room.global_position + Vector2(80, 490))
	p2.respawn_at(room.global_position + Vector2(800, 586))
	await _ticks(20)
	p1._invincible = 0
	p2.make_invincible(30)
	boss._enter(BarberBot.State.RAIN)
	var warnings := room.get_children().filter(func(n): return n.get_script() == Rain)
	check(warnings.size() == 2 and get_nodes_in_group("scissors").is_empty(), "overhead lanes warn both friends before anything falls")
	var marker: Node2D = warnings[0]
	var marked: Vector2 = marker.target
	if dodge: hold(p1, "right", true)
	await _ticks(45)
	check(is_instance_valid(marker) and marker.target == marked, "overhead marks stay at the original position instead of following the player")
	await _ticks(120)
	hold(p1, "right", false)
	check(p1.hp == 3 if dodge else p1.hp < 3, "walking away from the marked lane avoids the attack" if dodge else "standing on a high platform no longer makes the player untouchable")
