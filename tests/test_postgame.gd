extends SceneTree
## Persisted story flags, completion gate, modal focus and isolated room replays.
var passed := 0
var failed := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	Progress.save_path = "user://test_postgame.cfg"
	Progress.reset()
	var menu: MainMenu = await open_menu()
	menu._open_chapters()
	check(not menu._map_view.rooms_button.visible, "Rooms stays hidden before campaign completion")
	menu._open_rooms()
	check(not is_instance_valid(menu._collection), "early room selection is blocked in the handler too")
	menu._open_story()
	await frames()
	check(menu._collection_buttons[1].disabled, "ending replay stays locked before completing every chapter")
	for i in 7:
		await key(KEY_TAB)
		check(menu._collection.is_ancestor_of(root.gui_get_focus_owner()), "Story traps focus without selecting the covered map (%d)" % i)
	await key(KEY_P)
	check(current_scene == menu, "Play shortcut cannot launch the covered map")
	await key(KEY_ESCAPE)
	check(not is_instance_valid(menu._collection) and menu._chapters.visible, "Esc closes Story back to the map")
	menu.queue_free()
	await frames()
	# New flag persists across new ConfigFile reads, without a level-clear prerequisite.
	menu = await open_menu()
	menu._start_button.pressed.emit()
	await frames()
	check(current_scene.get_script() == load("res://scenes/ui/opening_cutscene.gd"), "fresh Start still plays the intro")
	var cfg := ConfigFile.new()
	cfg.load(Progress.save_path)
	check(cfg.get_value("story", "opening_seen", false), "first Start persists the intro flag before playback finishes")
	current_scene._elapsed = 0.4
	current_scene._try_skip()
	await frames()
	menu = current_scene
	menu._close_chapters()
	menu._start_button.pressed.emit()
	await frames()
	check(current_scene == menu and menu._chapters.visible, "second Start skips the intro even without chapter progress")
	menu.queue_free()
	await frames()
	for i in Progress.LEVELS.size(): Progress.record_clear(i, 100.0 + i, 2)
	check(Progress.campaign_completed() and not Progress.has_seen_ending(), "older completed saves unlock postgame without pretending they saw the new ending")
	menu = await open_menu()
	menu._open_chapters()
	menu._select_chapter(2)
	menu._opening_button.grab_focus()
	menu._opening_button.pressed.emit()
	await frames()
	check(menu._collection_buttons[1].disabled == false, "all chapter clears unlock the ending in Story")
	menu._collection_buttons[1].pressed.emit()
	await frames()
	var cg: Control = menu._collection.get_meta("cg")
	check(cg.get_script() == load("res://scenes/ui/ending_cutscene.gd") and not menu._collection.visible, "ending replay opens the supplied CG")
	cg._elapsed = 0.4
	cg._try_skip()
	await frames()
	check(menu._collection.visible and Progress.has_seen_ending(), "ending replay returns to Story and persists its seen flag")
	await key(KEY_ESCAPE)
	check(menu._selected_chapter == 2 and root.gui_get_focus_owner() == menu._opening_button, "closing Story preserves stage selection and returns focus")
	menu.queue_free()
	await frames()
	var room_count := 0
	for chapter in Progress.LEVELS.size():
		menu = await open_menu()
		menu._open_chapters()
		menu._select_chapter(chapter)
		menu._map_view.rooms_button.grab_focus()
		menu._map_view.rooms_button.pressed.emit()
		await frames()
		var count := menu._collection_buttons.size() - 1
		check(count == [3, 2, 3, 4][chapter] and menu._collection_kind == "rooms", "chapter %d lists its own rooms" % [chapter + 1])
		await key(KEY_TAB)
		check(menu._collection.is_ancestor_of(root.gui_get_focus_owner()), "room picker contains keyboard focus")
		await key(KEY_ESCAPE)
		for room in count:
			menu._play_room(chapter, room)
			await frames()
			var level: Level = current_scene
			check(level.room_replay and level.room_index == room and not paused, "chapter %d room %d launches directly" % [chapter + 1, room + 1])
			check(level.rooms[room].process_mode != Node.PROCESS_MODE_DISABLED and level.rooms.filter(func(r): return r.process_mode != Node.PROCESS_MODE_DISABLED).size() == 1, "only the chosen room simulates")
			check(level.players[0].hair == level.rooms[room].starting_hair[0] and level.players[1].hair == level.rooms[room].starting_hair[1], "room replay restores authored hair pair")
			if chapter == 3 and room == 2:
				level.restart_room()
				await frames()
				level = current_scene
				check(level.room_replay and level.room_index == room, "restart preserves single-room replay mode")
			level.level_time = 0.1
			level._on_room_cleared(level.rooms[room])
			await frames()
			check(paused and level.menu.is_open() and level.ending_cutscene == null and level.room_index == room, "room clear stops here without chapter transition or automatic CG")
			check(Progress.best_time(chapter) == 100.0 + chapter and Progress.best_deaths(chapter) == 2, "short room times and deaths never overwrite full-chapter records")
			level.menu.press("Replay room")
			await frames()
			level = current_scene
			check(level.room_replay and level.room_index == room and level.level_time < 1.0 and not paused, "Replay room starts the same room with fresh stats")
			level._on_room_cleared(level.rooms[room])
			level.menu.press("Choose another room")
			await frames()
			menu = current_scene
			check(menu._collection_kind == "rooms" and menu._selected_chapter == chapter and menu._collection_buttons.size() == count + 1, "Choose another room returns to this chapter's picker")
			menu._close_collection()
			await frames()
			room_count += 1
		menu.queue_free()
		await frames()
	check(room_count == 12, "every campaign room is replayable")
	Progress.reset()
	check(not Progress.has_seen_opening() and not Progress.has_seen_ending() and not Progress.campaign_completed(), "reset restores both first-view flags and postgame lock")
	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func open_menu() -> MainMenu:
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
