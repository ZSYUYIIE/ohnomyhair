extends SceneTree
## GPU bounds/readability checks for the trimmed, still-floating authored hints.
var passed := 0
var failed := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	Progress.save_path = "user://test_room_text.cfg"
	DirAccess.make_dir_recursive_absolute("res://.godot/room-text")
	for dimensions in [Vector2i(960, 540), Vector2i(1280, 800)]:
		DisplayServer.window_set_size(dimensions)
		for entry in Progress.LEVELS:
			var level: Level = load(entry.path).instantiate()
			root.add_child(level)
			for index in level.rooms.size():
				level.room_index = index
				level._activate_room(index)
				level._place_players()
				for player in level.players: player.set_frozen(true)
				level.camera.position = level.rooms[index].position
				level.camera.force_update_scroll()
				await settle()
				var title := "%dx%d-%s-%d" % [dimensions.x, dimensions.y, entry.id, index + 1]
				_check_hints(level, title)
				check(level.banner.text.is_empty(), title + ": no duplicate chapter/room title banner")
				await shot(title)
				if entry.id == "the_barber" and index == 3:
					var boss: BarberBot = level.rooms[index].get_node("BarberBot")
					boss.process_mode = Node.PROCESS_MODE_DISABLED
					# Keep the HUD live while only the boss's movement is frozen for captures.
					for bar in boss.get_children():
						if bar is BarberBot.BossBar: bar.process_mode = Node.PROCESS_MODE_ALWAYS
					for health in [7, 4]:
						boss.hp = health
						boss._stomped_by(level.players[1])
						Engine.time_scale = 1.0
						for frame in 200: await process_frame
						_check_hints(level, title + "-phase-%d" % boss.phase())
						await shot(title + "-phase-%d" % boss.phase())
			level.queue_free()
			await settle()
	Progress.reset()
	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func _check_hints(level: Level, title: String) -> void:
	var hints: Array[Label] = []
	for child in level.rooms[level.room_index].find_children("*", "Label", true, false):
		if child.is_visible_in_tree(): hints.append(child)
	check(hints.size() >= 1 and hints.size() <= 2, title + ": only one or two useful floating prompts")
	var fit := true
	var separate := true
	var hud: Hud = level.get_children().filter(func(n): return n is Hud)[0]
	for i in hints.size():
		var hint := hints[i]
		var rect: Rect2 = hint.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, hint.size)
		fit = fit and root.get_visible_rect().encloses(rect) and rect.end.y < hud._cards.position.y and hint.get_minimum_size().y <= hint.size.y + 1
		for j in range(i + 1, hints.size()):
			var other: Rect2 = hints[j].get_global_transform_with_canvas() * Rect2(Vector2.ZERO, hints[j].size)
			separate = separate and not rect.intersects(other)
	check(fit and separate, title + ": prompts fit above the HUD without overlapping each other")

func settle() -> void:
	for frame in 15: await process_frame
	await RenderingServer.frame_post_draw

func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/room-text/" + label + ".png")

func check(ok: bool, title: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("  ok   " if ok else "  FAIL ", title)
