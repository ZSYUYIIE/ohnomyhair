extends SceneTree
## Main menu and saved progress: level 1 open, later levels locked until the one before
## is cleared, best time shown, Play loads the level, level menu "Main menu" returns here.
## Run: godot --headless --path . --script res://tests/test_menu.gd

const MenuScene := preload("res://scenes/ui/main_menu.tscn")

var passed := 0
var failed := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	Progress.save_path = "user://test_menu_progress.cfg"
	Progress.reset()

	var menu: MainMenu = await _open_menu()
	check(not menu._play_buttons[0].disabled, "level 1 is always unlocked")
	check(menu._play_buttons[1].disabled and menu._play_buttons[2].disabled, "levels 2 and 3 start locked")
	menu.queue_free()

	check(Progress.record_clear(0, 83.4, 2), "first clear is a new best")
	check(not Progress.record_clear(0, 90.0, 1), "a slower clear isn't a new best time")
	check(is_equal_approx(Progress.best_time(0), 83.4) and Progress.best_deaths(0) == 1, "best time and fewest deaths are kept separately")
	check(Progress.format_time(83.4) == "1:23.4", "times read as m:ss.s")

	menu = await _open_menu()
	check(not menu._play_buttons[1].disabled and menu._play_buttons[2].disabled, "clearing level 1 unlocks level 2 only")
	check(get_root().gui_get_focus_owner() == menu._play_buttons[1], "focus starts on the furthest unlocked level")
	menu.play(1)
	await _frames(10)
	check(current_scene is Level and current_scene.scene_file_path.ends_with("level_02.tscn"), "Play loads that level")

	var level: Level = current_scene
	level.menu.show_pause(level.level_title, "x")
	level.menu.press("Main menu")
	await _frames(10)
	check(current_scene is MainMenu, "the level's Main menu button returns to the title screen")

	Progress.reset()
	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _open_menu() -> MainMenu:
	var menu: MainMenu = MenuScene.instantiate()
	root.add_child(menu)
	current_scene = menu
	await _frames(5)
	return menu


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("  ok   ", label)
	else:
		failed += 1
		print("  FAIL ", label)
