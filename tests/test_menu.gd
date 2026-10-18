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
	_legacy_save()
	Progress.reset()

	var menu: MainMenu = await _open_menu()
	check(menu._menu_buttons.size() == 2 and menu._menu_buttons.all(func(b): return b.text != "Style Lab"), "retired prototype is absent from the playable menu")
	check(not menu._play_buttons[0].disabled, "level 1 is always unlocked")
	check(menu._play_buttons[1].disabled and menu._play_buttons[2].disabled and menu._play_buttons[3].disabled, "chapters 2, 3 and 4 start locked")
	check(root.get_visible_rect().encloses(menu._controls_button.get_global_rect()), "title screen actions fit inside the viewport")
	menu._toggle_controls()
	await _frames(5)
	check(menu._controls.visible and menu._controls.is_ancestor_of(root.gui_get_focus_owner()), "help opens with keyboard focus inside the overlay")
	check(menu._controls.size == menu.size, "help overlay fills the screen and centers its panel")
	menu._controls._tabs.current_tab = 2
	await _frames(5)
	await _key(KEY_PAGEDOWN)
	var guide_scroll: ScrollContainer = menu._controls._tabs.get_current_tab_control().get_child(0)
	check(guide_scroll.scroll_vertical > 0, "story and checkpoint help scrolls with Page Down")
	menu._controls._tabs.current_tab = 0
	for i in 6:
		await _key(KEY_TAB)
		check(menu._controls.is_ancestor_of(root.gui_get_focus_owner()), "Tab stays inside help (%d)" % i)
	await _key(KEY_ESCAPE)
	check(not menu._controls.visible and root.gui_get_focus_owner() == menu._controls_button, "Esc closes help and returns focus to its opener")
	menu.play(1)
	await _frames(3)
	check(current_scene == menu, "locked chapters cannot be launched")
	await _key(KEY_ENTER)
	check(menu._controls.visible, "Enter opens help using the restored keyboard focus")
	await _key(KEY_ESCAPE)
	menu.queue_free()
	await _frames(3)
	check(not Progress.is_unlocked(-1) and not Progress.is_unlocked(Progress.LEVELS.size()), "invalid chapter indices never unlock")
	Progress.record_clear(2, 40.0, 0)
	Progress.record_clear(3, 50.0, 0)
	menu = await _open_menu()
	check(menu._play_buttons[3].disabled, "a saved chapter-3 clear cannot unlock chapter 4 while earlier chapters are missing")
	check(root.gui_get_focus_owner() == menu._play_buttons[0], "out-of-order saves keep keyboard focus on the first playable chapter")
	menu.play(3)
	await _frames(3)
	check(current_scene == menu, "chapter 4 cannot launch from an out-of-order save")
	Progress.record_clear(0, 30.0, 0)
	check(not Progress.is_unlocked(3), "chapter 4 stays locked until chapter 2 is cleared too")
	Progress.record_clear(1, 35.0, 0)
	check(Progress.is_unlocked(3) and Progress.best_time(3) == 50.0, "clearing every earlier chapter unlocks chapter 4 and preserves existing records")
	menu.queue_free()
	await _frames(3)
	Progress.reset()

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

	# Regression (playtest 4): restarting while the level is the current scene - as in
	# real play - lost track of the current scene (get_tree() after leaving the tree).
	var old_level: Level = current_scene
	old_level.restart_room()
	await _frames(10)
	check(current_scene is Level and current_scene != old_level and is_instance_valid(current_scene), "restarting a room keeps the fresh level as the current scene")
	# Playtest 4 screenshot: after a restart, "Next level" left the old level running under
	# the new one (two levels, two HUDs on screen). Exactly one level must remain.
	(current_scene as Level)._on_menu_chosen("next")
	await _frames(10)
	var levels := root.get_children().filter(func(n): return n is Level)
	check(levels.size() == 1 and current_scene == levels[0] and current_scene.scene_file_path.ends_with("level_03.tscn"), "after a restart, Next level replaces the level instead of stacking a second one")

	var level: Level = current_scene
	await _key(KEY_ESCAPE)
	check(paused and level.menu.is_open(), "Esc opens the pause menu")
	level.menu.press("How to play & combos")
	await _frames(5)
	check(paused and level.menu._guide.visible and not level.menu._panel.visible, "pause help keeps gameplay paused")
	await _key(KEY_ESCAPE)
	check(paused and not level.menu._guide.visible and level.menu._panel.visible, "Esc from help returns to pause without resuming gameplay")
	await _key(KEY_ESCAPE)
	check(not paused and not level.menu.is_open(), "Esc again resumes gameplay")
	await _key(KEY_ESCAPE, false)
	check(paused and level.menu.is_open(), "logical Esc also pauses without a physical scan code")
	await _key(KEY_ESCAPE, false)
	check(not paused and not level.menu.is_open(), "logical Esc resumes without a physical scan code")
	level.menu.show_death("P1")
	paused = true
	await _frames(5)
	await _key(KEY_ESCAPE)
	check(paused and level.menu.is_open(), "Esc cannot dismiss a death screen")
	# Playtest 5: R restarts straight from the death popup (no mouse needed) ...
	await _key(KEY_R)
	await _frames(5)
	check(not paused and current_scene is Level and current_scene != level and is_instance_valid(current_scene), "R on the death popup restarts the room")
	level = current_scene
	# ... and from the pause menu.
	await _key(KEY_ESCAPE)
	check(paused and level.menu.is_open(), "(pause menu open)")
	await _key(KEY_R)
	await _frames(5)
	check(not paused and current_scene is Level and current_scene != level, "R on the pause menu restarts the room")
	level = current_scene
	level.menu.show_pause(level.level_title, "x")
	level.menu.press("Main menu")
	await _frames(10)
	check(current_scene is MainMenu, "the level's Main menu button returns to the title screen")
	current_scene.queue_free()
	await _frames(3)
	for entry in Progress.LEVELS:
		var probe: Level = load(entry.path).instantiate()
		root.add_child(probe)
		current_scene = probe
		await _frames(5)
		var hud: Hud = probe.get_children().filter(func(n): return n is Hud)[0]
		var footer_top: float = hud._stage.get_parent().get_parent().get_global_rect().position.y
		for room in probe.rooms:
			probe.camera.position = room.position
			probe.camera.force_update_scroll()
			await _frames(3)
			var screen := room.get_global_transform_with_canvas()
			var top_left := screen * Vector2.ZERO
			var bottom_right := screen * Vector2(1280, 720)
			check(top_left.x >= 0 and top_left.y >= 0 and bottom_right.x <= root.get_visible_rect().size.x and bottom_right.y < footer_top, "%s / %s: entire room stays visible above HUD" % [entry.title, room.title])
		probe.queue_free()
		await _frames(3)

	await _clear_goes_straight_on()
	_exit_door_keeps_its_shape()

	Progress.reset()
	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _legacy_save() -> void:
	var legacy := ConfigFile.new()
	for i in 4:
		legacy.set_value("level_%d" % (i + 1), "best_time", 60.0 + i)
		legacy.set_value("level_%d" % (i + 1), "best_deaths", i)
	legacy.save(Progress.save_path)
	check(Progress.is_cleared(0) and Progress.best_time(2) == 62.0, "legacy save preserves the first three chapter records")
	check(Progress.LEVELS.size() == 4 and Progress.LEVELS[3].id == "the_barber", "campaign follows the two friends through four chapters")
	check(Progress.is_unlocked(3) and not Progress.is_unlocked(4), "original save unlocks the finale after the original three chapters")
	check(Progress.best_time(3) == 63.0 and Progress.best_deaths(3) == 3, "old boss records remain attached to the finale")
	var saved := ConfigFile.new()
	saved.load(Progress.save_path)
	check(saved.get_value("save", "version", 0) == Progress.SAVE_VERSION and not saved.has_section("level_4"), "migration persists its version and removes ambiguous positional records")
	check(Progress.best_time(3) == 63.0, "reloading a migrated save preserves its records")
	# Expansion saves already use IDs. Removed chapter records must not become
	# a finale clear or a prerequisite for the restored four-chapter route.
	saved.erase_section("the_barber")
	saved.set_value("perm_day", "best_time", 12.0)
	saved.set_value("extensions", "best_time", 13.0)
	saved.save(Progress.save_path)
	check(Progress.is_unlocked(3) and not Progress.is_cleared(3), "expansion chapter records neither gate nor clear the finale")


## Playtest 5: the results popup between levels broke the flow. Clearing a level now
## shows a CLEAR banner (time, deaths) and loads the next level by itself; only the last
## level stops on its results and ending.
func _clear_goes_straight_on() -> void:
	Progress.reset()
	var level: Level = load(Progress.LEVELS[0].path).instantiate()
	root.add_child(level)
	current_scene = level
	await _frames(5)
	level.room_index = level.rooms.size() - 1
	level._on_room_cleared(level.rooms[level.room_index])
	await _frames(3)
	check(level.banner.text.contains("CLEAR!") and level.banner.text.contains("death") and not level.menu.is_open(), "a level clear shows the CLEAR banner with time and deaths, no popup")
	await create_timer(Level.CLEAR_PAUSE + 0.5).timeout
	await _frames(5)
	check(current_scene is Level and current_scene.scene_file_path == Progress.LEVELS[1].path and not paused, "then the next level starts by itself")
	check(root.get_children().filter(func(n): return n is Level).size() == 1, "and the cleared level is gone")
	current_scene.queue_free()
	await _frames(3)

	for i in Progress.LEVELS.size() - 1:
		Progress.record_clear(i, 60.0, 0)
	level = load(Progress.LEVELS[-1].path).instantiate()
	root.add_child(level)
	current_scene = level
	await _frames(5)
	level.room_index = level.rooms.size() - 1
	level._on_room_cleared(level.rooms[level.room_index])
	await create_timer(Level.CLEAR_PAUSE + 0.5).timeout
	await _frames(5)
	check(current_scene == level and paused and level.menu.is_open() and "Play again" in level.menu.button_labels(), "the final level still ends on its results and ending")
	paused = false
	level.queue_free()
	await _frames(3)


## Playtest 5: L2's 4x2 exit squashed the door picture. The door keeps its 2:3 shape.
func _exit_door_keeps_its_shape() -> void:
	var exit: RoomExit = load("res://scenes/props/room_exit.tscn").instantiate()
	for size in [Vector2(128, 64), Vector2(64, 96), Vector2(64, 160)]:
		exit.size = size
		var door := exit.door_rect()
		check(absf(door.size.x / door.size.y - 2.0 / 3.0) < 0.01 and Rect2(Vector2.ZERO, size).encloses(door) and is_equal_approx(door.end.y, size.y), "exit %s: door stays 2:3, inside the exit, on the floor" % size)
	exit.free()


func _open_menu() -> MainMenu:
	var menu: MainMenu = MenuScene.instantiate()
	root.add_child(menu)
	current_scene = menu
	await _frames(5)
	return menu


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _key(code: Key, physical := true) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code if physical else KEY_NONE
	ev.pressed = true
	Input.parse_input_event(ev)
	await _frames(2)
	ev = ev.duplicate()
	ev.pressed = false
	Input.parse_input_event(ev)
	await _frames(3)


func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("  ok   ", label)
	else:
		failed += 1
		print("  FAIL ", label)
