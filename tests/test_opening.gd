extends SceneTree
## Verify first-start routing, exact timeline boundaries, skip inputs and save compatibility.
const Opening := preload("res://scenes/ui/opening_cutscene.gd")
var passed := 0
var failed := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	Progress.save_path = "user://test_opening.cfg"
	Progress.reset()
	check(not Progress.has_seen_opening(), "new saves have an unseen opening")
	var menu: MainMenu = await _menu()
	menu.play(3)
	await frames()
	check(current_scene == menu, "locked destination cannot start an opening or level")
	menu._open_chapters()
	menu._map_play.pressed.emit()
	await frames()
	check(current_scene.get_script() == Opening, "first map Play enters the supplied opening")
	var opening = current_scene
	opening.set_process(false)
	opening._shot_elapsed = 0.0
	opening._elapsed = 0.0
	opening._try_skip()
	check(not opening._finished, "opening click cannot also skip the first frame")
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/art/teammate_library_v1/cutscene_timeline.json"))
	check(source.shots.size() == Opening.SHOTS.size(), "every supplied storyboard panel is included")
	var total := 0.0
	for i in Opening.SHOTS.size():
		var shot: Dictionary = Opening.SHOTS[i]
		check(shot.texture.resource_path.ends_with(source.shots[i].image.get_file()) and shot.subtitle == source.shots[i].subtitle and shot.seconds == source.shots[i].duration_seconds,
			"panel %02d matches the teammate's image, subtitle and duration" % [i + 1])
		check(opening._shot_index == i and opening._subtitle.text == shot.subtitle, "panel %02d is displayed at its timeline boundary" % [i + 1])
		check(shot.texture.get_size() == Vector2(1280, 720), "panel %02d has the native 16:9 frame" % [i + 1])
		total += shot.seconds
		if i < Opening.SHOTS.size() - 1:
			opening._process(shot.seconds)
	check(total == 39.0, "the complete opening lasts exactly 39 seconds")
	opening._process(Opening.SHOTS[-1].seconds - 0.01)
	check(current_scene == opening and not Progress.has_seen_opening(), "final panel remains until the end of the timeline")
	opening._process(0.01)
	await frames()
	check(current_scene is Level and current_scene.scene_file_path == Progress.LEVELS[0].path, "natural completion enters Fresh Cut")
	check(Progress.has_seen_opening(), "natural completion persists the seen flag")
	current_scene.queue_free()
	await frames()
	menu = await _menu()
	menu.play(0)
	await frames()
	check(current_scene is Level, "returning to Play skips an already seen opening")
	current_scene.queue_free()
	await frames()
	for input_kind in ["keyboard", "mouse", "controller"]:
		Progress.reset()
		opening = Opening.new()
		root.add_child(opening)
		current_scene = opening
		opening.set_process(false)
		opening._elapsed = 0.4
		var event: InputEvent
		if input_kind == "keyboard":
			event = InputEventKey.new()
			event.keycode = KEY_SPACE
		elif input_kind == "mouse":
			event = InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_LEFT
		else:
			event = InputEventJoypadButton.new()
			event.button_index = JOY_BUTTON_A
		event.pressed = true
		Input.parse_input_event(event)
		await frames()
		check(current_scene is Level and Progress.has_seen_opening(), "%s can skip and persist the opening" % input_kind)
		current_scene.queue_free()
		await frames()
	Progress.reset()
	Progress.record_clear(0, 60.0, 2)
	check(Progress.has_seen_opening(), "existing progress resumes without a new mandatory opening")
	menu = await _menu()
	menu.play(1)
	await frames()
	check(current_scene is Level and current_scene.scene_file_path == Progress.LEVELS[1].path, "existing saves launch their selected unlocked chapter")
	current_scene.queue_free()
	await frames()
	menu = await _menu()
	menu._opening_button.pressed.emit()
	await frames()
	check(current_scene.get_script() == Opening and current_scene.return_to_menu, "Watch opening replays the CG even with existing progress")
	opening = current_scene
	opening.set_process(false)
	opening._elapsed = 0.4
	opening._try_skip()
	await frames()
	check(current_scene is MainMenu, "leaving the replay returns to the title")
	check(Progress.best_time(0) == 60.0 and Progress.is_unlocked(1), "replay preserves saved times and chapter unlocks")
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

func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("  ok   ", label)
	else:
		failed += 1
		print("  FAIL ", label)
