extends SceneTree
## Run with the normal renderer: actual window resizing and full-font layout.
var passed := 0
var failed := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	Progress.save_path = "user://test_ui_layout.cfg"
	Progress.reset()
	for i in Progress.LEVELS.size(): Progress.record_clear(i, 655.2, 123)
	DirAccess.make_dir_recursive_absolute("res://.godot/ui-layout")
	for dimensions in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(1280, 800)]:
		DisplayServer.window_set_size(dimensions)
		var menu: MainMenu = load(Progress.MAIN_MENU).instantiate()
		root.add_child(menu)
		await settle()
		await shot("%dx%d-title" % [dimensions.x, dimensions.y])
		menu._open_chapters()
		await settle()
		var screen := root.get_visible_rect()
		var label := "%dx%d" % [dimensions.x, dimensions.y]
		var details := menu._map_title.get_parent().get_parent().get_parent() as Control
		var shortcuts := menu._chapter_shortcuts.get_global_rect()
		check(screen.encloses(menu._chapter_footer.get_global_rect()), label + ": whole chapter footer fits the viewport")
		check(details.get_global_rect().end.y + 8 <= shortcuts.position.y, label + ": shortcuts have their own space below the details card")
		check(details.get_global_rect().encloses(menu._map_play.get_global_rect()), label + ": Play stays inside its panel")
		check(screen.encloses(shortcuts) and _text_fits(menu._map_detail), label + ": chapter records and shortcuts are fully visible")
		var card_bottom := 0.0
		for button in menu._play_buttons: card_bottom = maxf(card_bottom, button.get_global_rect().end.y)
		check(card_bottom + 12 < menu._chapter_footer.get_global_rect().position.y, label + ": map destinations do not overlap the footer")
		await click(menu._map_view.hit_areas[1].get_global_rect().get_center())
		check(menu._selected_chapter == 1 and root.gui_get_focus_owner() == menu._play_buttons[1], label + ": clicking the illustrated mirror selects chapter 2 and moves keyboard focus with it")
		await click(menu._play_buttons[2].get_global_rect().get_center())
		check(menu._selected_chapter == 2 and menu._map_title.text == Progress.LEVELS[2].title, label + ": clicking the separate label selects chapter 3")
		check(menu._map_view.marker.position.distance_to(menu._map_view.MARKER_FEET[2]) < 1.0 and menu._map_view.platforms.filter(func(p): return p.visible).size() == 1 and menu._map_view.platforms[2].visible, label + ": friends land on the selected circle and only that platform is gold")
		var canvas: Control = menu._map_view.canvas
		check(is_equal_approx(canvas.scale.x, canvas.scale.y) and screen.encloses(canvas.get_global_rect()), label + ": map and hit regions share an uncropped uniform scale")
		await shot(label + "-chapters")
		menu._opening_button.pressed.emit()
		await settle()
		check(screen.encloses(menu._collection.get_child(0).get_child(0).get_global_rect()), label + ": Story panel fits the screen")
		await shot(label + "-story")
		menu._close_collection()
		await settle()
		menu._map_view.rooms_button.pressed.emit()
		await settle()
		check(screen.encloses(menu._collection.get_child(0).get_child(0).get_global_rect()) and menu._collection_buttons.size() == 4, label + ": room picker fits and lists the chosen chapter")
		await shot(label + "-rooms")
		menu._close_collection()
		await settle()
		menu.queue_free()
		await settle()
		var level: Level = load(Progress.LEVELS[0].path).instantiate()
		level.start_room = 2
		root.add_child(level)
		for player in level.players: player.set_frozen(true)
		await settle()
		level.banner.modulate.a = 0
		var hud: Hud = level.get_children().filter(func(n): return n is Hud)[0]
		var fits := true
		for card: Control in hud._cards.get_children():
			fits = fits and screen.encloses(card.get_global_rect())
		for text: Label in [hud._stage, hud._stats, hud._keys[1], hud._keys[2], hud._names[1], hud._names[2]]:
			var card := text.get_parent()
			while not card is PanelContainer: card = card.get_parent()
			fits = fits and card.get_global_rect().encloses(text.get_global_rect()) and _text_fits(text)
		check(fits, label + ": both HUD rows stay inside their cards and screen")
		var room := level.rooms[level.room_index]
		level.camera.force_update_scroll()
		await settle()
		var bottom := (room.get_global_transform_with_canvas() * Room.SIZE).y
		check(bottom < hud._cards.get_global_rect().position.y, label + ": entire room stays above the footer")
		await shot(label + "-hud")
		level.queue_free()
		await settle()
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var route_menu: MainMenu = load(Progress.MAIN_MENU).instantiate()
	root.add_child(route_menu)
	route_menu._open_chapters()
	await settle()
	for chapter in 4:
		await click(route_menu._play_buttons[chapter].get_global_rect().get_center())
		for frame in 35: await process_frame
		var map: Control = route_menu._map_view
		check(map.marker.position.distance_to(map.MARKER_FEET[chapter]) < 0.1 and map.platforms[chapter].visible and map.platforms.filter(func(p): return p.visible).size() == 1, "stage %d: arrival settles on its circle with one gold platform" % (chapter + 1))
		await shot("map-selected-%d" % (chapter + 1))
	# A new choice interrupts the previous hop instead of letting old tweens pull it back.
	for chapter in [1, 3, 0, 2]:
		route_menu._select_chapter(chapter)
		await process_frame
	for frame in 40: await process_frame
	check(route_menu._map_view.marker.position.distance_to(route_menu._map_view.MARKER_FEET[2]) < 0.1 and route_menu._map_view.platforms[2].visible, "rapid selections settle at the final destination without stale animation")
	route_menu.queue_free()
	await settle()
	Progress.reset()
	var locked_menu: MainMenu = load(Progress.MAIN_MENU).instantiate()
	root.add_child(locked_menu)
	locked_menu._open_chapters()
	await settle()
	await click(locked_menu._map_view.hit_areas[3].get_global_rect().get_center())
	check(locked_menu._selected_chapter == 0 and locked_menu._map_view.toast.visible and locked_menu._map_view.locks[3].visible, "locked illustration explains its prerequisite without selecting or launching it")
	check(locked_menu._play_buttons[3].text == "???" and locked_menu._map_view.platforms[0].visible, "fresh map retains the mystery label and highlights the playable stop")
	check(locked_menu._map_view.marker.position.distance_to(locked_menu._map_view.MARKER_FEET[0]) < 0.1 and not locked_menu._map_view.platforms[3].visible, "clicking a locked stop leaves the friends and gold platform at stage 1")
	await shot("fresh-map")
	locked_menu.queue_free()
	await settle()
	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func _text_fits(label: Label) -> bool:
	var font := label.get_theme_font("font")
	var size := label.get_theme_font_size("font_size")
	return font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= label.size.x + 1 and label.get_minimum_size().y <= label.size.y + 1

func settle() -> void:
	for i in 10: await process_frame
	await RenderingServer.frame_post_draw

func click(at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = root.get_final_transform() * at
	Input.parse_input_event(motion)
	await settle()
	var event := InputEventMouseButton.new()
	event.position = motion.position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	Input.parse_input_event(event)
	await settle()
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await settle()

func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/ui-layout/" + label + ".png")

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("  ok   " if ok else "  FAIL ", label)
