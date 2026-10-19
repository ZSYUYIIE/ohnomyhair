extends SceneTree
## Ending timeline, paused gameplay, skip inputs and final-results navigation.
const Ending := preload("res://scenes/ui/ending_cutscene.gd")
var passed := 0
var failed := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	Progress.save_path = "user://test_ending.cfg"
	Progress.reset()
	var level := await finale()
	level.level_time = 123.0
	level.deaths = 2
	level._on_room_cleared(level.rooms[level.room_index])
	check(Progress.is_cleared(Progress.LEVELS.size() - 1), "final clear saves progress before the CG")
	check(level.banner.text.contains("CLEAR!") and not paused, "the CLEAR banner precedes the ending")
	await create_timer(Level.CLEAR_PAUSE + 0.1).timeout
	check(paused and is_instance_valid(level.ending_cutscene) and not level.menu.is_open(), "the ending runs over paused gameplay before results")
	var ending = level.ending_cutscene
	ending.set_process(false)
	ending._elapsed = 0.0
	ending._shot_elapsed = 0.0
	ending._try_skip()
	check(not ending._finished, "clear input cannot skip the first CG frame")
	var saved_time := Progress.best_time(Progress.LEVELS.size() - 1)
	await frames()
	check(level.level_time == saved_time, "CG playback does not increase the recorded level time")
	var timeline: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/art/ending_v1/ending_timeline.json"))
	check(Ending.SHOTS.size() == timeline.shots.size(), "all supplied ending panels are included")
	var total := 0.0
	for i in Ending.SHOTS.size():
		var shot: Dictionary = Ending.SHOTS[i]
		var authored: Dictionary = timeline.shots[i]
		check(shot.texture.resource_path.ends_with(authored.image.get_file()) and shot.seconds == authored.duration_seconds and shot.subtitle == authored.subtitle,
			"panel %02d matches the supplied image, duration and subtitle" % [i + 1])
		check(ending._shot_index == i and ending._subtitle.text == shot.subtitle and ending._counter.text == "%02d / 07" % [i + 1],
			"panel %02d displays at its timeline boundary" % [i + 1])
		check(shot.texture.get_size() == Vector2(1280, 720) and ending._strip.visible == not shot.subtitle.is_empty(),
			"panel %02d keeps native framing and the correct subtitle strip" % [i + 1])
		total += shot.seconds
		if i < Ending.SHOTS.size() - 1:
			ending._process(shot.seconds)
	check(total == timeline.total_seconds and total == 25.0, "the full ending lasts exactly 25 seconds")
	ending._process(3.99)
	check(not ending._finished and not level.menu.is_open() and ending._image.modulate.a < 0.03, "the final panel fades inside its authored duration")
	ending._process(0.02)
	ending._finish()
	await frames()
	check(level.ending_cutscene == null and not level.has_node("EndingCG") and level.menu.is_open() and paused, "natural completion opens results once and removes the overlay")
	check(Progress.best_time(Progress.LEVELS.size() - 1) == saved_time, "finishing the CG preserves the clear time")
	level.menu.press("Play again")
	await frames()
	level = current_scene
	check(level is Level and not paused and level.room_index == 0 and level.deaths == 0 and level.ending_cutscene == null, "Play again restarts the final chapter with fresh stats")
	await clear_scene()
	level = await finale()
	level._after_clear(false, false, Progress.LEVELS.size() - 1)
	check(level.ending_cutscene == null and level.menu.is_open() and Progress.has_seen_ending(), "later finale clears go directly to results with a persisted seen flag")
	await clear_scene()
	for kind in ["keyboard", "mouse", "controller", "button"]:
		Progress.reset()
		level = await finale()
		level._after_clear(false, false, Progress.LEVELS.size() - 1)
		ending = level.ending_cutscene
		ending.set_process(false)
		ending._elapsed = 0.4
		if kind == "button":
			ending._skip.pressed.emit()
		else:
			var event: InputEvent
			if kind == "keyboard":
				event = InputEventKey.new()
				event.keycode = KEY_ESCAPE
			elif kind == "mouse":
				event = InputEventMouseButton.new()
				event.button_index = MOUSE_BUTTON_LEFT
			else:
				event = InputEventJoypadButton.new()
				event.button_index = JOY_BUTTON_B
			event.pressed = true
			if kind == "mouse":
				ending._shot_index = Ending.SHOTS.size() - 1
				ending._gui_input(event)
			else:
				Input.parse_input_event(event)
		await frames()
		check(level.menu.is_open() and paused and level.ending_cutscene == null, "%s skips to results while gameplay remains paused" % kind)
		level.menu.press("Main menu")
		await frames()
		check(current_scene is MainMenu and not paused, "%s skip still allows returning to the main menu" % kind)
		await clear_scene()
	Progress.reset()
	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func finale() -> Level:
	var level: Level = load(Progress.LEVELS[-1].path).instantiate()
	level.start_room = 3
	root.add_child(level)
	current_scene = level
	await frames()
	return level

func clear_scene() -> void:
	paused = false
	current_scene.queue_free()
	await frames()

func frames() -> void:
	for i in 5: await process_frame

func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("  ok   ", label)
	else:
		failed += 1
		print("  FAIL ", label)
