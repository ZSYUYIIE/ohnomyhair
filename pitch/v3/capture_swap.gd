extends "res://tests/test_level_06.gd"

func _run() -> void:
	root.size = Vector2i(1280, 720)
	seed(7331)
	await load_level(LevelScene, 1)
	var o: float = level.rooms[1].global_position.x
	await walk_to(p2, o + 18 * TILE)
	await walk_to(p1, o + 20 * TILE)
	await _ticks(30)
	check(p1.ability is Pompadour and p2.ability is TwinTails, "capture: chair swaps the two haircuts")
	await walk_to(p1, o + 23 * TILE - 20)
	await tap(p1, "skill")
	await _ticks(45)
	finish()
