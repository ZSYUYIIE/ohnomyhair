class_name Level
extends Node2D
## Runs a level made of single-screen Rooms and pans to the next room once both
## friends reach the room's exit.
## A death pauses the game and asks: restart the room or go to the main menu.
## Restarting rebuilds the whole level scene at the current room, so every enemy,
## bell, door, gel wall and lever is reset too; the level's time and death count carry over.

## Emitted when restart_room() swaps this level for a fresh copy (tests follow it).
signal replaced(fresh: Level)

@export_file("*.tscn") var next_level := ""
## Handy while building: start the level in a later room.
@export var start_room := 0
@export var level_title := ""
## Shown after the last room of the last level, above the results.
@export_multiline var ending_text := ""

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
const StyleMenu := preload("res://scenes/ui/styling_menu.gd")
const StyleChair := preload("res://scenes/props/styling_chair.gd")
const HairAnchor := preload("res://scenes/props/hair_anchor.gd")
var styling_menu: CanvasLayer
var _active_chair: Area2D
var _checkpoint := {}


func _ready() -> void:
	# Fit the entire 1280 x 720 room above a dedicated 72 px HUD footer.
	# Keep a uniform scale and center it horizontally; physics stays in room units.
	camera.zoom = Vector2(0.9, 0.9)
	camera.offset = Vector2(-64.0 / 0.9, 0.0)
	add_child(Hud.new())
	menu = LevelMenu.new()
	add_child(menu)
	menu.chosen.connect(_on_menu_chosen)
	styling_menu = StyleMenu.new()
	add_child(styling_menu)
	styling_menu.styles_chosen.connect(_save_styles)
	styling_menu.closed.connect(func(): get_tree().paused = false)
	# The banner sits below the top edge, clear of the ceiling bells.
	banner.offset_top = 70.0
	banner.offset_bottom = 190.0
	for room in $Rooms.get_children():
		rooms.append(room)
		room.exit.both_inside.connect(_on_room_cleared.bind(room))
	for player in $Players.get_children():
		players.append(player)
		player.died.connect(_on_player_died)
	if _carry_over.get("path", "") == scene_file_path:
		start_room = _carry_over.room
		level_time = _carry_over.time
		deaths = _carry_over.deaths
		_checkpoint = _carry_over.get("checkpoint", {})
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
	_install_stations()
	show_banner(level_title + "\n" + rooms[room_index].title)


func _process(delta: float) -> void:
	if not _busy and not get_tree().paused:
		level_time += delta


func _unhandled_input(event: InputEvent) -> void:
	if menu.is_open():
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
			_checkpoint = {}
			_load_fresh(0, 0.0, 0)
		"next":
			get_tree().change_scene_to_file(next_level)
		"menu":
			get_tree().change_scene_to_file(Progress.MAIN_MENU)


## Rebuild the whole level at the current room: enemies, props and the hair swap reset,
## time and deaths carry over.
func restart_room() -> void:
	_load_fresh(room_index, level_time, deaths)


func _load_fresh(room: int, time: float, death_count: int) -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	_carry_over = {"path": scene_file_path, "room": room, "time": time, "deaths": death_count, "checkpoint": _checkpoint.duplicate(true)}
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
		if _checkpoint.get("room", -1) == room_index:
			player.set_hair(_checkpoint.hair[player.player_id - 1])
			at = _checkpoint.positions[player.player_id - 1]
		elif rooms[room_index].starting_hair.size() == 2:
			player.set_hair(rooms[room_index].starting_hair[player.player_id - 1])
		player.respawn_at(at)


func _on_room_cleared(room: Room) -> void:
	if _busy or room != rooms[room_index]:
		return
	_busy = true
	for player in players:
		player.set_frozen(true)

	if room_index == rooms.size() - 1:
		var index := Progress.index_of(scene_file_path)
		var new_best := Progress.record_clear(index, level_time, deaths)
		show_banner(level_title + " CLEAR!", 0.0)
		await get_tree().create_timer(2.0).timeout
		if ending_text != "":
			show_banner(ending_text, 0.0)
		get_tree().paused = true
		var next_index := Progress.index_of(next_level)
		menu.show_results(level_title, {
			"time": level_time, "deaths": deaths, "new_best": new_best,
			"best_time": Progress.best_time(index) if index >= 0 else level_time,
			"has_next": next_level != "" and ResourceLoader.exists(next_level) and Progress.is_unlocked(next_index),
			"ending": ending_text,
		})
		return

	room_index += 1
	_checkpoint = {}
	var pan := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pan.tween_property(camera, "position", rooms[room_index].position, 0.7)
	await pan.finished
	_activate_room(room_index)
	_place_players()
	for player in players:
		player.set_frozen(false)
	show_banner(rooms[room_index].title)
	_busy = false


func _install_stations() -> void:
	for room in rooms:
		if room.styles.size() < 2:
			continue
		var station := StyleChair.new()
		station.level = self
		station.name = "StylingStation"
		station.position = (room.get_node("SpawnP1").position + room.get_node("SpawnP2").position) / 2 + Vector2(80, 22)
		room.add_child(station)
		for child in room.get_children():
			if child is BarberBot:
				for at in [Vector2(160, 340), Vector2(1080, 340)]:
					var ring := HairAnchor.new()
					ring.position = at
					room.add_child(ring)


func open_styling(chair: Area2D) -> void:
	if _busy or get_tree().paused or chair.get_parent() != rooms[room_index]: return
	for player in players:
		if not player.alive or player.global_position.distance_to(chair.global_position) > 160:
			show_banner("Bring both friends to the styling chair", 1.5)
			return
	_active_chair = chair
	get_tree().paused = true
	styling_menu.open(players, rooms[room_index].styles)


func _save_styles(styles: Array[int]) -> void:
	get_tree().paused = false
	if not is_instance_valid(_active_chair) or styles.size() != players.size(): return
	# Two friends never share a haircut, and only the room's own styles are on offer.
	if styles[0] == styles[1] or styles.any(func(s): return s not in rooms[room_index].styles): return
	var positions: Array[Vector2] = []
	for i in players.size():
		players[i].set_hair(styles[i])
		players[i].heal(players[i].max_hp)
		players[i].dry()
		positions.append(_active_chair.global_position + Vector2(-24 if i == 0 else 24, -22))
	_checkpoint = {"room": room_index, "hair": styles.duplicate(), "positions": positions}
	show_banner("Fresh styles. Room checkpoint saved!", 1.8)


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
