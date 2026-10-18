class_name Progress
extends RefCounted
## Level list and saved progress (unlocks, best time, fewest deaths) in a ConfigFile.
## Level 1 is always unlocked; later levels require every preceding level cleared.

const LEVELS: Array[Dictionary] = [
	{"id": "fresh_cut", "path": "res://scenes/levels/level_01.tscn", "title": "Fresh Cut"},
	{"id": "return_to_sender", "path": "res://scenes/levels/level_02.tscn", "title": "Return to Sender"},
	{"id": "wash_and_blow_dry", "path": "res://scenes/levels/level_03.tscn", "title": "Wash & Blow-Dry"},
	# Keep the stable save ID and scene path: earlier finale records still belong here.
	{"id": "the_barber", "path": "res://scenes/levels/level_06.tscn", "title": "The Assistant"},
]
const MAIN_MENU := "res://scenes/ui/main_menu.tscn"
const SAVE_VERSION := 2

## Tests point this somewhere else so they don't touch the player's save.
static var save_path := "user://progress.cfg"


static func has_seen_opening() -> bool:
	var cfg := _load()
	if cfg.get_value("story", "opening_seen", false):
		return true
	# Existing players can continue without a new mandatory opening.
	for entry in LEVELS:
		if cfg.has_section_key(entry.id, "best_time"):
			return true
	return false


static func mark_opening_seen() -> void:
	var cfg := _load()
	cfg.set_value("story", "opening_seen", true)
	cfg.save(save_path)


static func has_seen_ending() -> bool:
	return _load().get_value("story", "ending_seen", false)


static func mark_ending_seen() -> void:
	var cfg := _load()
	cfg.set_value("story", "ending_seen", true)
	cfg.save(save_path)


static func campaign_completed() -> bool:
	for i in LEVELS.size():
		if not is_cleared(i): return false
	return true


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
	if index < 0 or index >= LEVELS.size():
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
	var cfg := ConfigFile.new()
	cfg.set_value("save", "version", SAVE_VERSION)
	cfg.save(save_path)


## "1:05.3"
static func format_time(seconds: float) -> String:
	if seconds < 0.0:
		return "--:--"
	return "%d:%04.1f" % [int(seconds) / 60, fmod(seconds, 60.0)]


static func _key(index: int) -> String:
	return LEVELS[index].id if index >= 0 and index < LEVELS.size() else ""


static func _load() -> ConfigFile:
	var cfg := ConfigFile.new()
	cfg.load(save_path)
	if cfg.get_value("save", "version", 1) < SAVE_VERSION:
		# In the four-chapter release level_4 was The Barber, before the two new
		# chapters were inserted. Stable chapter IDs prevent future reorderings
		# from granting a clear to an entirely different level.
		var legacy_ids := ["fresh_cut", "return_to_sender", "wash_and_blow_dry",
			"the_barber", "extensions", "the_barber"]
		for i in legacy_ids.size():
			var old_key := "level_%d" % (i + 1)
			for field in ["best_time", "best_deaths"]:
				if not cfg.has_section_key(old_key, field):
					continue
				var value = cfg.get_value(old_key, field)
				var existing = cfg.get_value(legacy_ids[i], field, -1)
				if existing < 0 or value < existing:
					cfg.set_value(legacy_ids[i], field, value)
			if cfg.has_section(old_key):
				cfg.erase_section(old_key)
		cfg.set_value("save", "version", SAVE_VERSION)
		cfg.save(save_path)
	return cfg
