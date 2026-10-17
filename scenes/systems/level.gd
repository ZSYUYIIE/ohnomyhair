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


func _ready() -> void:
	add_child(Hud.new())
	menu = LevelMenu.new()
	add_child(menu)
	menu.chosen.connect(_on_menu_chosen)
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
	else:
		# `godot ... -- --room=3` starts in room 3 (1-based) without editing the scene.
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--room="):
				start_room = arg.get_slice("=", 1).to_int() - 1
	_carry_over = {}
	room_index = clampi(start_room, 0, rooms.size() - 1)
	camera.position = rooms[room_index].position
	if rooms[room_index].starts_with_swapped_hair:
		for player in players:
			player.set_hair(Player.Hair.POMPADOUR if player.player_id == 1 else Player.Hair.TWIN_TAILS)
	_place_players()
	show_banner(level_title + "\n" + rooms[room_index].title)


func _process(delta: float) -> void:
	if not _busy and not get_tree().paused:
		level_time += delta


func _unhandled_input(event: InputEvent) -> void:
	if menu.is_open():
		return
	if event.is_action_pressed("pause") and not _busy:
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
	_carry_over = {"path": scene_file_path, "room": room, "time": time, "deaths": death_count}
	var fresh: Level = load(scene_file_path).instantiate()
	var parent := get_parent()
	var was_current := get_tree().current_scene == self
	parent.remove_child(self)
	parent.add_child(fresh)
	if was_current:
		get_tree().current_scene = fresh
	replaced.emit(fresh)
	queue_free()


func _place_players() -> void:
	for player in players:
		player.respawn_at(rooms[room_index].spawn_point(player.player_id))


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
		menu.show_results(level_title, {
			"time": level_time, "deaths": deaths, "new_best": new_best,
			"best_time": Progress.best_time(index) if index >= 0 else level_time,
			"has_next": next_level != "" and ResourceLoader.exists(next_level),
			"ending": ending_text,
		})
		return

	room_index += 1
	var pan := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pan.tween_property(camera, "position", rooms[room_index].position, 0.7)
	await pan.finished
	_place_players()
	for player in players:
		player.set_frozen(false)
	show_banner(rooms[room_index].title)
	_busy = false


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
