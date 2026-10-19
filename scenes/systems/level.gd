class_name Level
extends Node2D
## Runs a level made of single-screen Rooms and pans to the next room once both
## friends reach the room's exit. Clearing the last room shows a short CLEAR banner and
## goes straight on to the next level; the finale plays its CG before the results menu.
## A death pauses the game and asks: restart the room or go to the main menu.
## Restarting rebuilds the whole level scene at the current room, so every enemy,
## bell, door, gel wall and lever is reset too; the level's time and death count carry over.

## Emitted when restart_room() swaps this level for a fresh copy (tests follow it).
signal replaced(fresh: Level)

@export_file("*.tscn") var next_level := ""
## Handy while building: start the level in a later room.
@export var start_room := 0
## Postgame single-room practice; never writes campaign records or plays the ending.
var room_replay := false
@export var level_title := ""
## Shown after the last room of the last level, above the results.
@export_multiline var ending_text := ""
## Seconds the CLEAR banner stays up before the next level loads.
const CLEAR_PAUSE := 2.2

@onready var camera: Camera2D = $Camera2D
@onready var flash: ColorRect = $UI/Flash
@onready var banner: Label = $UI/Banner

var rooms: Array[Room] = []
var players: Array[Player] = []
var room_index := 0
## Seconds played in this level (paused time and room pans excluded) and deaths so far.
var level_time := 0.0
var deaths := 0
var menu: LevelMenu
var _busy := false
var _banner_tween: Tween

## Handed from a level to its fresh copy across restart_room().
static var _carry_over := {}
const Ending := preload("res://scenes/ui/ending_cutscene.gd")
var ending_cutscene: Control
## level_time when the current room (re)started, for the play log's room times.
var _room_t0 := 0.0


func _ready() -> void:
	# Fit the entire room above the HUD's reserved footer, including both text rows.
	# Keep a uniform scale and center it horizontally; physics stays in room units.
	var room_scale := (720.0 - Hud.FOOTER_HEIGHT) / 720.0
	var side_margin := (1280.0 - 1280.0 * room_scale) / 2.0
	camera.zoom = Vector2.ONE * room_scale
	camera.offset = Vector2(-side_margin / room_scale, 0.0)
	add_child(Hud.new())
	menu = LevelMenu.new()
	add_child(menu)
	menu.chosen.connect(_on_menu_chosen)
	# The banner sits below the top edge, clear of the ceiling bells.
	banner.offset_left = 120.0
	banner.offset_right = -120.0
	banner.offset_top = 74.0
	banner.offset_bottom = 138.0
	banner.add_theme_font_size_override("font_size", 24)
	banner.add_theme_constant_override("outline_size", 4)
	banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for room in $Rooms.get_children():
		rooms.append(room)
		room.exit.both_inside.connect(_on_room_cleared.bind(room))
	for player in $Players.get_children():
		players.append(player)
		player.died.connect(_on_player_died)
	var restarted: bool = _carry_over.get("path", "") == scene_file_path
	if restarted:
		start_room = _carry_over.room
		level_time = _carry_over.time
		deaths = _carry_over.deaths
		room_replay = _carry_over.get("room_replay", false)
	else:
		# `godot ... -- --room=3` starts in room 3 (1-based) without editing the scene.
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--room="):
				start_room = arg.get_slice("=", 1).to_int() - 1
	_carry_over = {}
	room_index = clampi(start_room, 0, rooms.size() - 1)
	_activate_room(room_index)
	camera.position = rooms[room_index].position
	_place_players()
	# Room names already live in the HUD. Reserve banners for actual events.
	banner.text = ""
	banner.modulate.a = 0.0
	_log_room_start(restarted)


func _process(delta: float) -> void:
	if not _busy and not get_tree().paused:
		level_time += delta


func _unhandled_input(event: InputEvent) -> void:
	if menu.is_open():
		return
	if event.is_action_pressed("show_help") and not _busy:
		get_viewport().set_input_as_handled()
		get_tree().paused = true
		menu.show_pause(level_title, rooms[room_index].title)
		menu.press("How to play & combos")
		menu._guide._tabs.current_tab = 4
		return
	if (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")) and not _busy:
		get_viewport().set_input_as_handled()
		get_tree().paused = true
		menu.show_pause(level_title, rooms[room_index].title)
	elif event.is_action_pressed("restart") and not _busy:
		restart_room()


func _on_player_died(player: Player) -> void:
	if _busy:
		return
	_busy = true
	deaths += 1
	var at := player.global_position - rooms[room_index].global_position
	Telemetry.log_event("death", self, {"player": player.player_id, "hair": player.ability.display_name,
		"x": snappedf(at.x, 0.1), "y": snappedf(at.y, 0.1), "wet": player.is_wet(),
		"cause": Telemetry.death_cause(player, rooms[room_index]), "room_time": snappedf(level_time - _room_t0, 0.01)})
	flash_screen(0.8, Color("ff5a5a"))
	await get_tree().create_timer(0.5).timeout
	get_tree().paused = true
	menu.show_death("P%d (%s)" % [player.player_id, player.ability.display_name])


func _on_menu_chosen(action: String) -> void:
	get_tree().paused = false
	match action:
		"resume":
			pass
		"restart":
			restart_room()
		"replay":
			_load_fresh(room_index if room_replay else 0, 0.0, 0)
		"next":
			get_tree().change_scene_to_file(next_level)
		"menu":
			get_tree().change_scene_to_file(Progress.MAIN_MENU)
		"rooms":
			var map_menu: MainMenu = load(Progress.MAIN_MENU).instantiate()
			var tree := get_tree()
			tree.root.add_child(map_menu)
			tree.current_scene = map_menu
			map_menu._open_chapters(Progress.index_of(scene_file_path))
			map_menu._open_rooms()
			queue_free()


## Rebuild the whole level at the current room: enemies, props and the hair swap reset,
## time and deaths carry over.
func restart_room() -> void:
	_load_fresh(room_index, level_time, deaths)


func _load_fresh(room: int, time: float, death_count: int) -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	_carry_over = {"path": scene_file_path, "room": room, "time": time, "deaths": death_count, "room_replay": room_replay}
	var fresh: Level = load(scene_file_path).instantiate()
	# Grab the tree first: once this level is removed from it, get_tree() returns null.
	var tree := get_tree()
	var parent := get_parent()
	var was_current := tree.current_scene == self
	parent.remove_child(self)
	parent.add_child(fresh)
	if was_current:
		tree.current_scene = fresh
	replaced.emit(fresh)
	queue_free()


## Only the current room runs: enemies, turrets and timed hazards in rooms you haven't
## reached stay frozen, so every room starts the same way when you get there (the boss
## doesn't charge around - or shoot - while you're still two rooms back).
func _activate_room(index: int) -> void:
	for i in rooms.size():
		rooms[i].process_mode = Node.PROCESS_MODE_INHERIT if i == index else Node.PROCESS_MODE_DISABLED


func _place_players() -> void:
	for player in players:
		var at := rooms[room_index].spawn_point(player.player_id)
		if rooms[room_index].starting_hair.size() == 2:
			player.set_hair(rooms[room_index].starting_hair[player.player_id - 1])
		player.respawn_at(at)


func _on_room_cleared(room: Room) -> void:
	if _busy or room != rooms[room_index]:
		return
	_busy = true
	Telemetry.log_event("room_clear", self, {"room_time": snappedf(level_time - _room_t0, 0.01)})
	for player in players:
		player.set_frozen(true)
	if room_replay:
		Sound.play("room_clear", 0.0)
		get_tree().paused = true
		menu.show_room_results(rooms[room_index].title, level_time, deaths)
		return

	if room_index == rooms.size() - 1:
		Sound.play("level_clear", 0.0)
		_on_level_cleared()
		return
	Sound.play("room_clear", 0.0)

	room_index += 1
	var pan := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pan.tween_property(camera, "position", rooms[room_index].position, 0.7)
	await pan.finished
	_activate_room(room_index)
	_place_players()
	for player in players:
		player.set_frozen(false)
	_log_room_start(false)
	_busy = false


func _log_room_start(restarted: bool) -> void:
	_room_t0 = level_time
	Telemetry.log_event("room_start", self, {"restart": restarted,
		"pair": [Player.HAIR_INFO[players[0].hair].name, Player.HAIR_INFO[players[1].hair].name]})


## Last room cleared: record the time, show it in the banner, then keep the flow going
## into the next level. The finale plays its ending before showing the results.
func _on_level_cleared() -> void:
	var index := Progress.index_of(scene_file_path)
	var new_best := Progress.record_clear(index, level_time, deaths)
	var has_next := next_level != "" and ResourceLoader.exists(next_level) and Progress.is_unlocked(Progress.index_of(next_level))
	var stats := "%s   |   %d %s%s" % [Progress.format_time(level_time), deaths, "death" if deaths == 1 else "deaths",
			"   |   NEW BEST!" if new_best else ""]
	show_banner("%s CLEAR!\n%s" % [level_title, stats], 0.0)
	# Bound to this level: if it's freed first (main menu, a test), the timer just does nothing.
	get_tree().create_timer(CLEAR_PAUSE).timeout.connect(_after_clear.bind(has_next, new_best, index))


func _after_clear(has_next: bool, new_best: bool, index: int) -> void:
	if has_next and ending_text == "":
		# Only the running game moves on; a level embedded elsewhere (tests) stays put.
		if get_tree().current_scene == self:
			get_tree().change_scene_to_file(next_level)
		return
	if ending_text != "":
		show_banner(ending_text, 0.0)
	get_tree().paused = true
	if ending_text != "" and not Progress.has_seen_ending():
		# Keep the finished level and its stats; only the CG runs while gameplay is paused.
		Progress.mark_ending_seen()
		var overlay := CanvasLayer.new()
		overlay.name = "EndingCG"
		overlay.layer = 30
		overlay.process_mode = Node.PROCESS_MODE_ALWAYS
		ending_cutscene = Ending.new()
		ending_cutscene.finished.connect(func():
			overlay.queue_free()
			ending_cutscene = null
			_show_results(has_next, new_best, index))
		overlay.add_child(ending_cutscene)
		add_child(overlay)
		return
	_show_results(has_next, new_best, index)


func _show_results(has_next: bool, new_best: bool, index: int) -> void:
	menu.show_results(level_title, {
		"time": level_time, "deaths": deaths, "new_best": new_best,
		"best_time": Progress.best_time(index) if index >= 0 else level_time,
		"has_next": has_next,
		"ending": ending_text,
	})


## Show a banner on the level that `node` lives in (does nothing outside a level).
static func banner_for(node: Node, text: String, seconds := 2.0) -> void:
	var n := node
	while n and not (n is Level):
		n = n.get_parent()
	if n:
		(n as Level).show_banner(text, seconds)


func flash_screen(alpha: float, color := Color.WHITE) -> void:
	flash.color = Color(color, alpha)
	# Keeps fading while the death popup has the game paused.
	create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).tween_property(flash, "color:a", 0.0, 0.4)


func show_banner(text: String, hide_after := 2.0) -> void:
	if _banner_tween:
		_banner_tween.kill()
	banner.text = text
	banner.modulate.a = 1.0
	if hide_after > 0.0:
		_banner_tween = create_tween()
		_banner_tween.tween_interval(hide_after)
		_banner_tween.tween_property(banner, "modulate:a", 0.0, 0.5)
