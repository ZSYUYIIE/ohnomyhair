class_name Sound
extends Node
## Sound effects and music, all synthesized by tools/audio/ (make_sfx.py, make_music.py).
## Nothing to put in a scene: the first Sound.play() / Sound.music() creates one Sound
## node under the tree root, which then lives for the whole game.
##   Sound.play("jump")       one-shot effect from assets/audio/sfx/jump.wav
##   Sound.music("calm")      loop from assets/audio/music/calm.wav (cross-fades)
## By itself it also: picks the music for the current scene and room (title screen,
## each level, the boss room), and clicks/chimes every menu button (focus + press), so
## the UI scripts need no sound code.

const SFX := "res://assets/audio/sfx/%s.wav"
const MUSIC := "res://assets/audio/music/%s.wav"
const VOICES := 12
const SFX_DB := -5.0
const MUSIC_DB := -14.0
## The same effect again within this many ms is skipped (a glide held over a dryer...).
const REPEAT_MS := 45
## Music per level scene; a room with a BarberBot in it plays "boss" instead.
const LEVEL_MUSIC := {"level_01": "calm", "level_02": "tense", "level_03": "calm", "level_06": "tense"}

static var _inst: Sound
static var muted := false

var _voices: Array[AudioStreamPlayer] = []
var _next := 0
var _streams := {}
var _last_played := {}
var _music: AudioStreamPlayer
var _track := ""
var _pending: Array[Callable] = []
var _poll := 0.0


static func play(sound_name: String, pitch_jitter := 0.06, volume_db := 0.0) -> void:
	var s := _instance()
	if s:
		s._play(sound_name, pitch_jitter, volume_db)


static func music(track: String) -> void:
	var s := _instance()
	if s:
		s._set_music(track)


static func _instance() -> Sound:
	if is_instance_valid(_inst):
		return _inst
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or DisplayServer.get_name() == "headless":
		return null  # tests and tools run silent
	_inst = Sound.new()
	_inst.name = "Sound"
	tree.root.add_child.call_deferred(_inst)
	return _inst


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # menus pause the tree; their clicks still play
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.volume_db = SFX_DB
		_voices.append(p)
		add_child(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = MUSIC_DB
	add_child(_music)


func _ready() -> void:
	for bus in ["UI", "SFX", "Music"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("UI"), -5.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), -3.0)
	_music.bus = "Music"
	get_tree().node_added.connect(_on_node_added)
	for button in get_tree().root.find_children("*", "BaseButton", true, false):
		_on_node_added(button)
	for call in _pending:
		call.call()
	_pending.clear()


func _process(delta: float) -> void:
	_poll -= delta
	if _poll > 0.0:
		return
	_poll = 0.25
	var track := _track_for_scene()
	if track != "":
		_set_music(track)


func _exit_tree() -> void:
	_pending.clear()
	_streams.clear()
	if _inst == self:
		_inst = null


func _track_for_scene() -> String:
	var scene := get_tree().current_scene
	if scene is Level:
		var level := scene as Level
		if level.rooms.size() > level.room_index:
			for child in level.rooms[level.room_index].get_children():
				if child is BarberBot:
					return "boss"
		return LEVEL_MUSIC.get(level.scene_file_path.get_file().get_basename(), "calm")
	if scene and scene.scene_file_path == Progress.MAIN_MENU:
		return "menu"
	return ""


func _play(sound_name: String, pitch_jitter: float, volume_db: float) -> void:
	if not is_inside_tree():
		_pending.append(_play.bind(sound_name, pitch_jitter, volume_db))
		return
	if muted:
		return
	var now := Time.get_ticks_msec()
	if now - int(_last_played.get(sound_name, -1000)) < REPEAT_MS:
		return
	_last_played[sound_name] = now
	var stream := _stream(SFX % sound_name)
	if stream == null:
		return
	var voice := _voices[_next]
	_next = (_next + 1) % VOICES
	voice.stream = stream
	voice.bus = "UI" if sound_name.begins_with("ui_") else "SFX"
	voice.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	voice.volume_db = SFX_DB + volume_db
	voice.play()


func _set_music(track: String) -> void:
	if not is_inside_tree():
		_pending.append(_set_music.bind(track))
		return
	if track == _track:
		return
	_track = track
	var stream := _stream(MUSIC % track) as AudioStreamWAV
	if stream == null:
		return
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	var fade := create_tween()
	if _music.playing:
		fade.tween_property(_music, "volume_db", -40.0, 0.6)
	fade.tween_callback(func():
		_music.stream = stream
		_music.volume_db = -40.0 if not muted else -80.0
		_music.play())
	fade.tween_property(_music, "volume_db", MUSIC_DB if not muted else -80.0, 0.8)


func _stream(path: String) -> AudioStream:
	if not _streams.has(path):
		_streams[path] = load(path) if ResourceLoader.exists(path) else null
	return _streams[path]


## Every menu button: a soft tick on focus, a chime on press (back/cancel buttons get the
## falling one).
func _on_node_added(node: Node) -> void:
	if not node is BaseButton or node.has_meta("sound_hooked"):
		return
	node.set_meta("sound_hooked", true)
	UiTheme.wire_button(node)
	node.mouse_entered.connect(func():
		if not node.disabled: _play("ui_move", 0.0, -5.0))
	node.focus_entered.connect(func(): _play("ui_move", 0.0, 0.0))
	node.pressed.connect(func():
		var text := String(node.get("text")).to_lower()
		var back := text.contains("back") or text.contains("cancel") or text.contains("menu") or text.contains("quit")
		_play("ui_back" if back else "ui_confirm", 0.0, 0.0))
