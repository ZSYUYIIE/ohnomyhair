extends SceneTree
## Real mouse hits on the visible stage discs, followed by overlay round-trips.
var passed := 0
var failed := 0
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	Progress.save_path = "user://test_map_selection.cfg"
	Progress.reset()
	for i in 4: Progress.record_clear(i,60.0,0)
	var menu: MainMenu = load(Progress.MAIN_MENU).instantiate()
	root.add_child(menu)
	current_scene = menu
	menu._open_chapters()
	await frames(8)
	# The front faces are visibly part of the stage platforms too, not empty road.
	var points := [Vector2(300,636),Vector2(590,344),Vector2(1050,595),Vector2(1450,407)]
	for i in 4:
		menu._select_chapter((i+1)%4)
		await click(menu._map_view.canvas.get_global_transform() * points[i])
		check(menu._selected_chapter == i, "stage %d: clicking the visible platform's front selects it" % [i+1])
	for i in 4:
		await click(menu._play_buttons[i].get_global_rect().get_center())
		check(menu._selected_chapter == i, "stage %d: its label remains selectable" % [i+1])
		menu._toggle_controls()
		await frames(4)
		menu._controls.dismiss()
		await frames(6)
		check(menu._selected_chapter == i, "stage %d: closing help preserves the selected destination" % [i+1])
		menu._opening_button.pressed.emit()
		await frames(4)
		menu._close_collection()
		await frames(6)
		check(menu._selected_chapter == i, "stage %d: Story round-trip preserves the selected destination" % [i+1])
	menu.queue_free()
	await frames(5)
	for i in 4:
		menu = load(Progress.MAIN_MENU).instantiate()
		root.add_child(menu)
		current_scene = menu
		menu._open_chapters()
		await frames(6)
		await click(menu._map_view.canvas.get_global_transform() * points[i])
		await click(menu._map_play.get_global_rect().get_center())
		check(current_scene is Level and current_scene.scene_file_path == Progress.LEVELS[i].path, "stage %d: Play starts the chapter selected through its platform" % [i+1])
		current_scene.queue_free()
		await frames(5)
	Progress.reset()
	menu = load(Progress.MAIN_MENU).instantiate()
	root.add_child(menu)
	current_scene = menu
	menu._open_chapters()
	await frames(6)
	for i in range(1,4):
		await click(menu._map_view.canvas.get_global_transform() * points[i])
		check(menu._selected_chapter == 0 and menu._map_view.toast.visible, "stage %d: expanded mouse region still respects progression locks" % [i+1])
	menu.queue_free()
	await frames(5)
	Progress.reset()
	print("Results: %d passed, %d failed" % [passed,failed])
	quit(1 if failed else 0)
func click(at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = root.get_final_transform() * at
	Input.parse_input_event(motion)
	await frames(3)
	var e := InputEventMouseButton.new()
	e.position = motion.position
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	Input.parse_input_event(e)
	await frames(3)
	e = e.duplicate()
	e.pressed = false
	Input.parse_input_event(e)
	await frames(6)
func frames(count: int) -> void:
	for i in count: await process_frame
func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("ok " if ok else "FAIL ",label)
