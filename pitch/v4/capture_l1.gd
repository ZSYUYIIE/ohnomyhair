extends "res://tests/test_level_01.gd"
## Real renderer + PlayBot inputs; isolated test save inherited from PlayBot.

var shot := "sling"
var cues: Array[Dictionary] = []

func mark(label: String) -> void:
	cues.append({"label": label, "frame": Engine.get_frames_drawn()})
	print("CAPTURE ", label, " ", Engine.get_frames_drawn())

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			shot = arg.trim_prefix("--shot=")
	root.size = Vector2i(1280, 720)
	seed(7331)
	mark("start")
	if shot == "failure":
		await _carry_alone_fails()
	else:
		await load_level(LevelScene, 2)
		mark("room_ready")
		await _room_3()
	mark("end")
	var file := FileAccess.open("res://build/pitch-v4-capture/" + shot + "-cues.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(cues, "  "))
	finish()
