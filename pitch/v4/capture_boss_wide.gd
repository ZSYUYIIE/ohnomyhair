extends "res://tests/test_level_06.gd"
## Staged phase demonstration, using real arena attacks, showers and reinforcements.
func _run() -> void:
	root.size = Vector2i(1280, 720)
	seed(7331)
	await load_level(LevelScene, 3)
	p1.make_invincible(999.0)
	p2.make_invincible(999.0)
	var room := level.rooms[3]
	var boss: BarberBot = room.get_node("BarberBot")
	p1.global_position = room.global_position + Vector2(18 * TILE, 18 * TILE)
	p2.global_position = room.global_position + Vector2(27 * TILE, 18 * TILE)
	await _ticks(240)
	boss.hp = 6
	boss.phase_changed.emit(2)
	boss.backup_called.emit()
	await _ticks(720)
	check(boss.phase() == 2, "capture: latest phase-two arena runs")
	finish()
