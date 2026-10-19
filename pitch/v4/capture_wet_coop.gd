extends "res://tests/test_level_03.gd"
func _run() -> void:
	root.size = Vector2i(1280, 720)
	seed(7331)
	await load_level(LevelScene, 2)
	await _room_3()
	finish()
