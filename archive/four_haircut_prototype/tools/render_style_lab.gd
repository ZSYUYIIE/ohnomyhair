extends SceneTree
## GPU screenshots for the expansion and its selection/help UI. Never uses real saves.
var out := "res://.godot/style-lab-shots"
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	Progress.save_path = "user://render_style_lab_progress.cfg"
	Progress.reset()
	var menu: MainMenu = load(Progress.MAIN_MENU).instantiate()
	root.add_child(menu)
	await settle()
	await shot("title")
	menu._toggle_controls()
	menu._controls._tabs.current_tab = 2
	await settle()
	await shot("new-style-help")
	var scroll: ScrollContainer = menu._controls._tabs.get_current_tab_control().get_child(0)
	scroll.scroll_vertical = 1000
	await settle()
	await shot("new-style-help-scrolled")
	menu.queue_free()
	await settle()
	for r in 3:
		var level: Level = load("res://scenes/levels/style_lab.tscn").instantiate()
		level.start_room = r
		root.add_child(level)
		await settle()
		level.banner.modulate.a = 0
		await shot("lab-room-%d" % (r + 1))
		if r == 0:
			level.open_styling(level.rooms[0].get_node("StylingStation"))
			level.styling_menu.choose(1, Player.Hair.LONG_STRAIGHT)
			await settle()
			await shot("styling-chair")
			DisplayServer.window_set_size(Vector2i(960, 540))
			await settle()
			await shot("styling-chair-960x540")
			DisplayServer.window_set_size(Vector2i(1280, 960))
			await settle()
			await shot("styling-chair-4x3")
			DisplayServer.window_set_size(Vector2i(1280, 720))
			await settle()
			level.styling_menu.dismiss()
		level.queue_free()
		await settle()
	quit()
func settle() -> void:
	for i in 45: await process_frame
func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(out.path_join(label + ".png")))
	print("Saved ", label)
