extends SceneTree
## Margin table: for every gap and height a room asks the players to clear, how much room
## to spare each allowed move has. The moves are MEASURED now, in an empty arena, with the
## game's current physics (nothing hard-coded), so a tuning change shows up here at once.
## Gate sizes come from the level builders (`rb.gate(name, verbs, {"gap": w, "drop": d})`
## or `{"rise": h}`, in tiles). Writes JSON for tools/difficulty/report.py.
## Run: godot --headless --fixed-fps 60 --path . --script res://tools/difficulty/margins.gd
## Output: $OUT, or user://difficulty/margins.json.

const TILE := 32.0
const PlayerScene := preload("res://scenes/player/player.tscn")
const GAP_VERBS := ["jump", "glide", "carry"]
const RISE_VERBS := ["jump", "launch"]

var _arena: Node2D
var _cache := {}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var rows := []
	var paths: Array = Progress.LEVELS.map(func(e): return e.path)
	for path in paths:
		var level: Level = load(path).instantiate()
		for room: Room in level.get_node("Rooms").get_children():
			var verbs_allowed := PackedStringArray()
			for pair in StyleRules.pairs(room.styles):
				for v in StyleRules.verbs(pair):
					if v not in verbs_allowed:
						verbs_allowed.append(v)
			for gate in room.gates:
				var spec: Dictionary = gate.get("spec", {})
				if spec.is_empty():
					continue
				for verb in gate.any:
					if verb not in verbs_allowed:
						continue
					var have := await _capability(verb, spec)
					if have < 0.0:
						continue
					var need: float = spec.get("gap", spec.get("rise", 0.0))
					rows.append({"level": path.get_file().get_basename(), "room": room.title, "gate": gate.name,
						"verb": verb, "kind": "gap" if spec.has("gap") else "rise", "need": need,
						"drop": spec.get("drop", 0), "have": snappedf(have, 0.01), "slack": snappedf(have - need, 0.01)})
		level.free()
	var out := OS.get_environment("OUT")
	if out == "":
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://difficulty"))
		out = ProjectSettings.globalize_path("user://difficulty/margins.json")
	var file := FileAccess.open(out, FileAccess.WRITE)
	file.store_string(JSON.stringify({"margins": rows, "measured": _cache}, "  "))
	file.close()
	for r in rows:
		print("%-10s %-24s %-44s %-12s need %5.1f  have %5.1f  slack %+5.1f" % [r.level, r.room, r.gate, r.verb, r.need, r.have, r.slack])
	print(out, " written")
	quit()


## How far (gap, tiles) or how high (rise, tiles) this verb gets, or -1 if not measurable.
func _capability(verb: String, spec: Dictionary) -> float:
	if spec.has("gap") and verb in GAP_VERBS:
		var drop: int = spec.get("drop", 0)
		match verb:
			"jump": return await _cached("jump_reach_%d" % drop, _flight.bind(false, false, drop))
			"glide": return await _cached("glide_reach_%d" % drop, _flight.bind(true, false, drop))
			"carry": return await _cached("carry_reach_%d" % drop, _flight.bind(true, true, drop))
	if spec.has("rise") and verb in RISE_VERBS:
		match verb:
			"jump": return await _cached("jump_rise", _jump_rise)
			"launch": return await _cached("launch_rise", _launch_rise)
	return -1.0


func _cached(key: String, measure: Callable) -> float:
	if not _cache.has(key):
		_cache[key] = snappedf(await measure.call(), 0.01)
	return _cache[key]


# --- Arena ------------------------------------------------------------------------

func _new_arena() -> void:
	for action in InputMap.get_actions():
		Input.action_release(action)
	if is_instance_valid(_arena):
		_arena.free()
	_arena = Node2D.new()
	root.add_child(_arena)
	_box(Rect2(-4000, 0, 12000, 64))


func _box(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = Layers.WORLD
	body.position = rect.position
	Player.add_rect_shape(body, rect.size, rect.size / 2)
	_arena.add_child(body)


func _player(id: int, hair: int, feet: Vector2) -> Player:
	var p: Player = PlayerScene.instantiate()
	p.player_id = id
	p.hair = hair
	p.position = feet - Vector2(0, Player.HALF_SIZE.y)
	_arena.add_child(p)
	return p


func _ticks(n: int) -> void:
	for i in n:
		await physics_frame


func _hold(p: Player, action: String, on: bool) -> void:
	if on:
		Input.action_press(p.act(action))
	else:
		Input.action_release(p.act(action))


## Run off a ledge `drop` tiles above the floor (flat ground when 0), jumping at the lip.
## Returns the widest gap (tiles) whose far side the lowest friend's feet still reach.
func _flight(hold_skill: bool, with_friend: bool, drop: int) -> float:
	_new_arena()
	var top := -drop * TILE
	if drop > 0:
		_box(Rect2(-3000, top, 3000, drop * TILE))
	var a := _player(1, Player.Hair.TWIN_TAILS, Vector2(-500, top))
	var b: Player = _player(2, Player.Hair.POMPADOUR, Vector2(-470, top)) if with_friend else null
	if not with_friend:
		_player(2, Player.Hair.POMPADOUR, Vector2(-2500, top))
	await _ticks(15)
	if hold_skill:
		_hold(a, "skill", true)
	await _ticks(2)
	_hold(a, "right", true)
	var jumped_at := -1
	var landed_x := 0.0
	for i in 900:
		await physics_frame
		if jumped_at < 0 and a.global_position.x >= 4.0:
			_hold(a, "jump", true)
			jumped_at = i
		if jumped_at >= 0 and i > jumped_at + 5 and a.is_on_floor() and a.global_position.y + Player.HALF_SIZE.y > top + 4.0 - (0.0 if drop > 0 else 8.0):
			landed_x = a.global_position.x
			if b:
				landed_x = minf(landed_x, b.global_position.x)
			break
	for action in InputMap.get_actions():
		Input.action_release(action)
	# The far side starts `gap` tiles past the lip; landing needs the body half on it.
	return (landed_x + Player.HALF_SIZE.x - 2.0) / TILE


func _jump_rise() -> float:
	_new_arena()
	var a := _player(1, Player.Hair.TWIN_TAILS, Vector2.ZERO)
	_player(2, Player.Hair.POMPADOUR, Vector2(-600, 0))
	await _ticks(15)
	_hold(a, "jump", true)
	var peak := 0.0
	for i in 60:
		await physics_frame
		peak = maxf(peak, -(a.global_position.y + Player.HALF_SIZE.y))
	return peak / TILE


## The rider's feet peak above the floor; a ledge this high is just reachable.
func _launch_rise() -> float:
	_new_arena()
	var base := _player(2, Player.Hair.POMPADOUR, Vector2.ZERO)
	var rider := _player(1, Player.Hair.TWIN_TAILS, Vector2(0, -2 * Player.HALF_SIZE.y - 2))
	await _ticks(20)
	_hold(base, "skill", true)
	await physics_frame
	_hold(base, "skill", false)
	return await _peak(rider)


func _peak(p: Player) -> float:
	var peak := 0.0
	for i in 150:
		await physics_frame
		peak = maxf(peak, -(p.global_position.y + Player.HALF_SIZE.y))
	return peak / TILE
