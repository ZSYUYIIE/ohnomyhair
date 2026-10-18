extends SceneTree
## Death heatmaps: renders each room that has deaths in the play logs and marks every
## death on it (red = people, orange = sloppy bots). Needs a real window (not --headless).
## Inputs: $LOGS, a ';'-separated list of telemetry folders (default: user://telemetry and
## user://telemetry_bots). Output: $OUT_DIR/<level>_R<n>.png (default user://difficulty).
## Run: godot --path . --script res://tools/difficulty/heatmap.gd

const COLORS := {"human": Color(0.86, 0.1, 0.16, 0.55), "bot-sloppy": Color(1.0, 0.55, 0.0, 0.5), "bot": Color(0.4, 0.4, 0.4, 0.5)}


class Marks extends Node2D:
	var points := []   # [Vector2, source]

	func _draw() -> void:
		for entry in points:
			var color: Color = COLORS.get(entry[1], Color(0.2, 0.2, 0.8, 0.5))
			draw_circle(entry[0], 16.0, Color(color, color.a * 0.35))
			draw_circle(entry[0], 7.0, color)
			draw_arc(entry[0], 7.0, 0, TAU, 16, Color(0.17, 0.13, 0.25, 0.9), 1.5)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	Telemetry.enabled = false  # rendering must not log room starts
	var dirs := OS.get_environment("LOGS")
	var folders: PackedStringArray = dirs.split(";", false) if dirs != "" else PackedStringArray(["user://telemetry", "user://telemetry_bots"])
	var out := OS.get_environment("OUT_DIR")
	if out == "":
		out = ProjectSettings.globalize_path("user://difficulty")
	DirAccess.make_dir_recursive_absolute(out)
	var deaths := {}   # "level|room" -> [[Vector2, source], ...]
	for folder in folders:
		var d := DirAccess.open(folder)
		if d == null:
			continue
		for name in d.get_files():
			if not name.ends_with(".jsonl"):
				continue
			var file := FileAccess.open(folder.path_join(name), FileAccess.READ)
			while not file.eof_reached():
				var line := file.get_line()
				if line.strip_edges() == "":
					continue
				var e = JSON.parse_string(line)
				if e is Dictionary and e.get("kind") == "death":
					var key := "%s|%d" % [e.level, int(e.room)]
					if not deaths.has(key):
						deaths[key] = []
					deaths[key].append([Vector2(e.x, e.y), e.get("source", "human")])
	var keys := deaths.keys()
	keys.sort()
	for key: String in keys:
		var level_name := key.get_slice("|", 0)
		var room_index := key.get_slice("|", 1).to_int()
		var path := "res://scenes/levels/%s.tscn" % level_name
		if not ResourceLoader.exists(path):
			continue
		var lvl: Level = load(path).instantiate()
		lvl.start_room = room_index
		root.add_child(lvl)
		for i in 30: await process_frame
		lvl.banner.modulate.a = 0.0
		for p in lvl.players:
			p.hide()
		var marks := Marks.new()
		marks.z_index = 100
		marks.points = deaths[key]
		lvl.rooms[room_index].add_child(marks)
		for i in 3: await process_frame
		var file_name := "%s_R%d.png" % [level_name, room_index + 1]
		root.get_viewport().get_texture().get_image().save_png(out.path_join(file_name))
		print("%s: %d deaths" % [file_name, deaths[key].size()])
		lvl.queue_free()
		for i in 3: await process_frame
	print("heatmaps written to ", out)
	quit()
