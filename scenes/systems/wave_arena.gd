class_name WaveArena
extends Node2D
## Robots arrive in batches. Each wave drops clipper bots through ceiling vents (a vent
## flashes and sheds dust first) and can wake up sleeping hazards in the room - scissor
## dispensers, hot irons. When every robot of a wave is scrapped, the next one comes after
## a short breather. After the last wave the hazards switch off, `cleared` fires (wire it
## to a door) and growth tonics appear for the fight ahead.
## With auto_start off the arena waits for start_next() (the boss calls in backup this way).
## Position is the room's top-left corner; it only runs while its room is the current one.

signal wave_started(number: int)
signal cleared

## [{"drops": [tile columns], "wake": [names of the room's sleeping hazards],
##   "tonic": tile column of a growth tonic for the breather after it}, ...]
@export var waves: Array[Dictionary] = []
@export var auto_start := true
@export var start_delay := 1.5
@export var breather := 1.6
## Tile columns where growth tonics appear once the arena is cleared (tile row `tonic_row`).
@export var tonic_cols: PackedInt32Array = []
@export var tonic_row := 18
@export var vent_row := 1
@export var patrol_tiles := 3.0
## Hits a wave robot takes: 1 = one dash breaks it. A horde is about numbers, not toughness.
@export var robot_hp := 1

const TILE := 32.0
const WARN_TIME := 0.9

var wave := -1          # index of the running wave, -1 before the first
var is_cleared := false
var robots: Array[Node] = []
var _wait := 0.0
var _warning := {}      # column -> seconds of warning left
var _started := false
var _t := 0.0


func _ready() -> void:
	# Hazards named in any wave sleep until their wave wakes them.
	for w in waves:
		for hazard_name in w.get("wake", []):
			_set_awake(get_parent().get_node(hazard_name), false)


func _physics_process(delta: float) -> void:
	_t += delta
	if not _started and auto_start:
		_started = true
		_wait = start_delay
	for col in _warning.keys():
		_warning[col] -= delta
		if _warning[col] <= 0.0:
			_warning.erase(col)
			_drop_robot(col)
	queue_redraw()
	if is_cleared or wave >= waves.size() or not _started:
		return
	if _wait > 0.0:
		_wait -= delta
		if _wait <= 0.0:
			_begin_wave(wave + 1)
		return
	if wave >= 0 and _warning.is_empty() and robots_left() == 0:
		if wave == waves.size() - 1:
			_finish()
		else:
			_wait = breather
			Level.banner_for(self, "Wave %d cleared!" % (wave + 1), 1.2)
			if waves[wave].has("tonic"):
				_place_tonic(waves[wave].tonic)


## Start the next wave now (a boss's call for backup).
func start_next() -> void:
	_started = true
	_wait = 0.0
	_begin_wave(wave + 1)


func robots_left() -> int:
	robots = robots.filter(func(r): return is_instance_valid(r))
	return robots.size()


## The fight is over (a boss went down): scrap whatever is still running.
func scrap_all() -> void:
	_warning.clear()
	for r in robots:
		if is_instance_valid(r):
			r.queue_free()
	robots.clear()


func _begin_wave(index: int) -> void:
	if index >= waves.size():
		return
	wave = index
	var w: Dictionary = waves[index]
	for col in w.get("drops", []):
		_warning[col] = WARN_TIME
	for hazard_name in w.get("wake", []):
		_set_awake(get_parent().get_node(hazard_name), true)
	if auto_start:
		Level.banner_for(self, "WAVE %d / %d" % [index + 1, waves.size()], 1.4)
	wave_started.emit(index + 1)


func _drop_robot(col: int) -> void:
	var bot := ClipperBot.new()
	bot.position = position + Vector2(col * TILE + TILE / 2.0, (vent_row + 1) * TILE + ClipperBot.SIZE.y)
	bot.patrol_range = patrol_tiles * TILE
	bot.hp = robot_hp
	get_parent().add_child(bot)
	robots.append(bot)


func _finish() -> void:
	is_cleared = true
	for w in waves:
		for hazard_name in w.get("wake", []):
			_set_awake(get_parent().get_node(hazard_name), false)
	for col in tonic_cols:
		_place_tonic(col)
	Level.banner_for(self, "All robots scrapped!", 1.8)
	cleared.emit()


func _place_tonic(col: int) -> void:
	var tonic := GrowthTonic.new()
	tonic.position = position + Vector2(col * TILE + TILE / 2.0, tonic_row * TILE + TILE / 2.0)
	get_parent().add_child(tonic)


## Dispensers and irons sleep by being switched off: a sleeping dispenser stops firing
## (drawn dimmed), an unplugged iron stays cold.
func _set_awake(hazard: Node, awake: bool) -> void:
	if hazard is HotIron:
		hazard.active = awake
	else:
		hazard.process_mode = Node.PROCESS_MODE_INHERIT if awake else Node.PROCESS_MODE_DISABLED
		hazard.modulate = Color.WHITE if awake else Color(0.62, 0.6, 0.68)


func _draw() -> void:
	# Ceiling vents for every column a robot can drop from; a vent about to drop one
	# flashes red/yellow and sheds dust.
	var cols := {}
	for w in waves:
		for col in w.get("drops", []):
			cols[col] = true
	for col in cols:
		var c := Vector2(col * TILE + TILE / 2.0, (vent_row + 1) * TILE)
		var warn: bool = _warning.has(col)
		var lit := warn and int(_t * 10.0) % 2 == 0
		draw_rect(Rect2(c.x - 22, c.y - 4, 44, 10), Color("2b2140"))
		draw_rect(Rect2(c.x - 19, c.y - 1, 38, 4), Color("f1c40f") if lit else Color("e74c3c") if warn else Color("6b6278"))
		for i in 4:
			draw_line(Vector2(c.x - 15 + i * 10, c.y - 2), Vector2(c.x - 15 + i * 10, c.y + 4), Color("2b2140"), 2.0)
		if warn:
			for i in 5:
				var y := fmod(_t * 160.0 + i * 23.0, 60.0)
				draw_circle(Vector2(c.x - 14 + i * 7, c.y + 8 + y), 2.0, Color(0.55, 0.5, 0.5, 0.8))
