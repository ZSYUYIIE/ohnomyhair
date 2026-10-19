extends SceneTree
## Navigation shortcuts must respect locks, overlays, replay saves and gameplay pause.
var passed := 0
var failed := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	Progress.save_path = "user://test_navigation.cfg"
	Progress.reset()
	var menu: MainMenu = await _menu()
	await key(KEY_F1)
	check(menu._controls.visible and menu._controls._tabs.current_tab == 4, "F1 opens the shortcut guide from the title")
	await key(KEY_H)
	check(not menu._controls.visible, "H closes help without activating a covered menu")
	menu._open_chapters()
	await frames()
	await key(KEY_4)
	check(menu._selected_chapter == 0, "number shortcuts cannot select locked chapters")
	await key(KEY_H)
	check(menu._controls.visible and menu._map_play.focus_mode == Control.FOCUS_NONE, "chapter help keeps Play out of the focus loop")
	await key(KEY_ESCAPE)
	await key(KEY_ESCAPE)
	await key(KEY_I)
	check(menu._collection_kind == "story", "I opens Story from the title")
	menu._collection_buttons[0].pressed.emit()
	await frames()
	var opening = menu._collection.get_meta("cg")
	opening._elapsed = 0.4
	await key(KEY_ESCAPE)
	check(current_scene == menu and menu._collection.visible and not Progress.has_seen_opening(), "replay returns to Story without changing a fresh save")
	await key(KEY_ESCAPE)
	current_scene.queue_free()
	await frames()
	Progress.record_clear(0, 60.0, 0)
	menu = await _menu()
	menu._open_chapters()
	await frames()
	await key(KEY_1)
	check(menu._selected_chapter == 0, "1 selects the first chapter")
	await key(KEY_KP_2)
	check(menu._selected_chapter == 1, "numpad 2 selects an unlocked second chapter")
	await key(KEY_1)
	await key(KEY_P)
	check(current_scene is Level and current_scene.scene_file_path == Progress.LEVELS[0].path, "P plays the selected chapter")
	var level: Level = current_scene
	await key(KEY_F1)
	check(paused and level.menu._guide.visible and level.menu._guide._tabs.current_tab == 4, "F1 pauses gameplay and opens shortcuts")
	await key(KEY_ESCAPE)
	check(paused and level.menu.is_open() and not level.menu._guide.visible, "Esc from help returns to pause")
	await key(KEY_H)
	check(paused and level.menu._guide.visible, "H also opens help from pause")
	await key(KEY_H)
	await key(KEY_R)
	check(current_scene is Level and current_scene != level and not paused, "R from pause restarts and resumes the room")
	current_scene.queue_free()
	await frames()
	Progress.reset()
	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func _menu() -> MainMenu:
	var menu: MainMenu = load(Progress.MAIN_MENU).instantiate()
	root.add_child(menu)
	current_scene = menu
	await frames()
	return menu

func frames() -> void:
	for i in 5: await process_frame

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await frames()
	event.pressed = false
	Input.parse_input_event(event)
	await frames()

func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("  ok   ", label)
	else:
		failed += 1
		print("  FAIL ", label)
