class_name Level
extends Node2D
## Runs a level made of single-screen Rooms: respawns both players when either
## dies, and pans to the next room once both reach the room's exit.

@export_file("*.tscn") var next_level := ""
## Handy while building: start the level in a later room.
@export var start_room := 0
@export var level_title := ""
## Shown after the last room of the last level instead of loading next_level.
@export_multiline var ending_text := ""

@onready var camera: Camera2D = $Camera2D
@onready var flash: ColorRect = $UI/Flash
@onready var banner: Label = $UI/Banner

var rooms: Array[Room] = []
var players: Array[Player] = []
var room_index := 0
var _busy := false
var _banner_tween: Tween


func _ready() -> void:
	add_child(Hud.new())
	for room in $Rooms.get_children():
		rooms.append(room)
		room.exit.both_inside.connect(_on_room_cleared.bind(room))
	for player in $Players.get_children():
		players.append(player)
		player.died.connect(_on_player_died)
	# `godot ... -- --room=3` starts in room 3 (1-based) without editing the scene.
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--room="):
			start_room = arg.get_slice("=", 1).to_int() - 1
	room_index = clampi(start_room, 0, rooms.size() - 1)
	camera.position = rooms[room_index].position
	if rooms[room_index].starts_with_swapped_hair:
		for player in players:
			player.set_hair(Player.Hair.POMPADOUR if player.player_id == 1 else Player.Hair.TWIN_TAILS)
	_place_players()
	show_banner(level_title + "\n" + rooms[room_index].title)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") and not _busy:
		_place_players()


func _on_player_died(_player: Player) -> void:
	if _busy:
		return
	_busy = true
	flash_screen(0.8)
	await get_tree().create_timer(0.45).timeout
	_place_players()
	_busy = false


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
		show_banner(level_title + " CLEAR!", 0.0)
		await get_tree().create_timer(2.0).timeout
		if ending_text != "":
			show_banner(ending_text, 0.0)
		elif next_level != "" and ResourceLoader.exists(next_level):
			get_tree().change_scene_to_file(next_level)
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
	create_tween().tween_property(flash, "color:a", 0.0, 0.4)


func show_banner(text: String, hide_after := 2.0) -> void:
	if _banner_tween:
		_banner_tween.kill()
	banner.text = text
	banner.modulate.a = 1.0
	if hide_after > 0.0:
		_banner_tween = create_tween()
		_banner_tween.tween_interval(hide_after)
		_banner_tween.tween_property(banner, "modulate:a", 0.0, 0.5)
