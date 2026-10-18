class_name Progress
extends RefCounted
## Level list and saved progress (unlocks, best time, fewest deaths) in a ConfigFile.
## Level 1 is always unlocked; later levels require every preceding level cleared.

const LEVELS: Array[Dictionary] = [
	{"path": "res://scenes/levels/level_01.tscn", "title": "Fresh Cut"},
	{"path": "res://scenes/levels/level_02.tscn", "title": "Return to Sender"},
	{"path": "res://scenes/levels/level_03.tscn", "title": "Wash & Blow-Dry"},
	{"path": "res://scenes/levels/level_04.tscn", "title": "Perm Day"},
	{"path": "res://scenes/levels/level_05.tscn", "title": "Extensions"},
	{"path": "res://scenes/levels/level_06.tscn", "title": "The Barber"},
]
const MAIN_MENU := "res://scenes/ui/main_menu.tscn"

## Tests point this somewhere else so they don't touch the player's save.
static var save_path := "user://progress.cfg"


static func index_of(scene_path: String) -> int:
	for i in LEVELS.size():
		if LEVELS[i].path == scene_path:
			return i
	return -1


static func is_unlocked(index: int) -> bool:
	if index < 0 or index >= LEVELS.size():
		return false
	var cfg := _load()
	for previous in index:
		if not cfg.has_section_key(_key(previous), "best_time"):
			return false
	return true


static func is_cleared(index: int) -> bool:
	return _load().has_section_key(_key(index), "best_time")


## Best time in seconds, or -1 if never cleared.
static func best_time(index: int) -> float:
	return _load().get_value(_key(index), "best_time", -1.0)


static func best_deaths(index: int) -> int:
	return _load().get_value(_key(index), "best_deaths", -1)


## Records a clear; returns true if it set a new best time.
static func record_clear(index: int, seconds: float, deaths: int) -> bool:
	if index < 0:
		return false
	var cfg := _load()
	var key := _key(index)
	var old_time: float = cfg.get_value(key, "best_time", -1.0)
	var old_deaths: int = cfg.get_value(key, "best_deaths", -1)
	var new_best := old_time < 0.0 or seconds < old_time
	if new_best:
		cfg.set_value(key, "best_time", seconds)
	if old_deaths < 0 or deaths < old_deaths:
		cfg.set_value(key, "best_deaths", deaths)
	cfg.save(save_path)
	return new_best


static func reset() -> void:
	ConfigFile.new().save(save_path)


## "1:05.3"
static func format_time(seconds: float) -> String:
	if seconds < 0.0:
		return "--:--"
	return "%d:%04.1f" % [int(seconds) / 60, fmod(seconds, 60.0)]


static func _key(index: int) -> String:
	return "level_%d" % (index + 1)


static func _load() -> ConfigFile:
	var cfg := ConfigFile.new()
	cfg.load(save_path)
	return cfg
