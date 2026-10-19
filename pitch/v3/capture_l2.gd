extends "res://tests/test_level_02.gd"

func _run() -> void:
	root.size = Vector2i(1280, 720)
	seed(7331)
	await load_level(LevelScene)
	await _room_1()
	await _ticks(40)
	finish()
