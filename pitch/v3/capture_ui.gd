extends SceneTree

func _initialize() -> void:
	Progress.save_path = "user://pitch_v3_ui.cfg"
	Progress.reset()
	_run.call_deferred()

func ticks(n: int) -> void:
	for i in n:
		await process_frame

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var menu := preload("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await ticks(60)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://pitch/editor/public/v3/menu.png")
	menu._open_chapters()
	await ticks(60)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://pitch/editor/public/v3/chapters.png")
	await ticks(90)
	quit()
