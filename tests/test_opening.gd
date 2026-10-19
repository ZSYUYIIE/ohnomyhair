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
	check(current_scene == menu and not menu._chapters.visible, "launch stays on the title until the player chooses Start Game")
	await frames()
	check(current_scene == menu, "waiting on the title does not auto-start the CG")
	menu._start_button.pressed.emit()
	await frames()
	check(current_scene.get_script() == Opening, "Start Game enters the supplied opening before the map")
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
	check(current_scene == opening and Progress.has_seen_opening(), "the first Start persists its flag while the final panel remains visible")
	opening._process(0.01)
	await frames()
	check(current_scene is MainMenu and current_scene._chapters.visible, "natural completion opens the stage map")
	check(Progress.has_seen_opening(), "natural completion persists the seen flag")
	current_scene.queue_free()
	await frames()
	menu = await _menu()
	menu.play(0)
	await frames()
	check(current_scene is Level, "returning to Play skips an already seen opening")
	current_scene.queue_free()
	await frames()
	for input_kind in ["mouse", "keyboard", "controller"]:
		Progress.reset()
		opening = Opening.new()
		root.add_child(opening)
		current_scene = opening
		opening.set_process(false)
		await frames()
		opening._elapsed = 0.1
		_send(_advance_event(input_kind))
		await frames()
		check(opening._shot_index == 0, "%s page turn waits out the opening grace period" % input_kind)
		opening._elapsed = 0.4
		_send(_advance_event(input_kind))
		await frames()
		check(opening._shot_index == 1 and opening._subtitle.text == Opening.SHOTS[1].subtitle and current_scene == opening,
			"%s turns to the next page instead of skipping" % input_kind)
		opening._elapsed = 0.4 + Opening.ADVANCE_COOLDOWN - 0.01
		_send(_advance_event(input_kind))
		await frames()
		check(opening._shot_index == 1, "%s page turns are rate-limited" % input_kind)
		opening._elapsed = 0.4 + Opening.ADVANCE_COOLDOWN
		_send(_advance_event(input_kind))
		await frames()
		check(opening._shot_index == 2, "%s turns again once the cooldown passes" % input_kind)
		opening._elapsed = 0.4 + Opening.ADVANCE_COOLDOWN * 2.0
		var modifier := InputEventKey.new()
		modifier.keycode = KEY_SHIFT
		modifier.pressed = true
		_send(modifier)
		await frames()
		check(current_scene == opening and opening._shot_index == 2, "%s run: a lone modifier key neither skips nor turns" % input_kind)
		var other := InputEventKey.new()
		other.keycode = KEY_A
		other.pressed = true
		_send(other)
		await frames()
		check(current_scene == opening and opening._shot_index == 3, "%s run: any other key turns the page" % input_kind)
		opening._elapsed = 0.4 + Opening.ADVANCE_COOLDOWN * 3.0
		var pad := InputEventJoypadButton.new()
		pad.button_index = JOY_BUTTON_X
		pad.pressed = true
		_send(pad)
		await frames()
		check(current_scene == opening and opening._shot_index == 4, "%s run: any other pad button turns the page" % input_kind)
		_send(_skip_event(input_kind))
		await frames()
		check(current_scene is Level and Progress.has_seen_opening(), "%s can skip and persist the opening" % input_kind)
		current_scene.queue_free()
		await frames()
	# Clicking the Skip button ends the opening rather than turning a page.
	Progress.reset()
	opening = Opening.new()
	root.add_child(opening)
	current_scene = opening
	opening.set_process(false)
	await frames()
	opening._elapsed = 0.4
	var on_skip := InputEventMouseButton.new()
	on_skip.button_index = MOUSE_BUTTON_LEFT
	on_skip.position = _to_window(opening._skip.get_global_rect().get_center())
	on_skip.pressed = true
	_send(on_skip)
	await frames()
	check(current_scene is Level and Progress.has_seen_opening(), "clicking Skip ends the opening")
	current_scene.queue_free()
	await frames()
	# Turning past the last page ends the opening like natural completion.
	Progress.reset()
	opening = Opening.new()
	root.add_child(opening)
	current_scene = opening
	opening.set_process(false)
	await frames()
	opening._elapsed = 10.0
	opening._shot_index = Opening.SHOTS.size() - 1
	opening._show_shot()
	opening._advance()
	await frames()
	check(current_scene is Level and Progress.has_seen_opening(), "turning past the last page enters the level")
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
	check(not menu._opening_button.is_visible_in_tree(), "the title keeps only its two painted actions")
	var enter := InputEventKey.new()
	enter.keycode = KEY_ENTER
	enter.pressed = true
	_send(enter)
	await frames()
	check(current_scene == menu and menu._chapters.visible, "Enter on Start Game skips the intro for an existing save")
	check(current_scene is MainMenu and current_scene._chapters.visible and current_scene._selected_chapter == 1, "returning Start opens the latest unlocked stage")
	check(Progress.best_time(0) == 60.0, "entry CG preserves saved records")
	menu = current_scene
	menu._open_chapters()
	await frames()
	menu._opening_button.pressed.emit()
	await frames()
	check(menu._collection_kind == "story" and menu._opening_button.text == "Story", "Story opens the CG collection")
	menu._collection_buttons[0].pressed.emit()
	await frames()
	opening = menu._collection.get_meta("cg")
	opening.set_process(false)
	opening._elapsed = 0.4
	opening._try_skip()
	await frames()
	check(current_scene == menu and menu._collection.visible, "leaving the replay returns to Story on the same map")
	menu._close_collection()
	await frames()
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

func _advance_event(kind: String) -> InputEvent:
	var event: InputEvent
	if kind == "mouse":
		event = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = _to_window(Vector2(640, 360))
	elif kind == "keyboard":
		event = InputEventKey.new()
		event.keycode = KEY_SPACE
	else:
		event = InputEventJoypadButton.new()
		event.button_index = JOY_BUTTON_A
	event.pressed = true
	return event

func _skip_event(kind: String) -> InputEvent:
	var event: InputEvent
	if kind == "controller":
		event = InputEventJoypadButton.new()
		event.button_index = JOY_BUTTON_B
	else:
		event = InputEventKey.new()
		event.keycode = KEY_ESCAPE
	event.pressed = true
	return event

## Mouse events arrive in window pixels; headless windows are tiny and canvas_items stretch rescales.
func _to_window(point: Vector2) -> Vector2:
	return root.get_final_transform() * point

## Press, then release, so mouse button state doesn't leak between checks.
func _send(event: InputEvent) -> void:
	Input.parse_input_event(event)
	var up: InputEvent = event.duplicate()
	up.pressed = false
	Input.parse_input_event(up)

func frames() -> void:
	for i in 5: await process_frame

func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("  ok   ", label)
	else:
		failed += 1
		print("  FAIL ", label)
