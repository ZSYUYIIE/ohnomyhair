class_name Telemetry
extends RefCounted
## Local play log for difficulty tuning: every room start, room clear and death goes to
## one JSON object per line in <dir>/<session>.jsonl. Nothing leaves the machine.
## Real games write to user://telemetry; the test bots switch `dir` and `source` so their
## runs never mix with people's. tools/difficulty/ turns the logs into the difficulty
## report and the death heatmaps (docs/difficulty/README.md).

static var dir := "user://telemetry"
static var source := "human"
static var enabled := true
static var _path := ""


static func log_event(kind: String, level: Level, data := {}) -> void:
	if not enabled or level == null:
		return
	var room: Room = level.rooms[level.room_index] if level.rooms.size() > level.room_index else null
	var entry := {
		"kind": kind,
		"t": Time.get_unix_time_from_system(),
		"source": source,
		"level": level.scene_file_path.get_file().get_basename(),
		"room": level.room_index,
		"room_title": room.title if room else "",
		"level_time": snappedf(level.level_time, 0.01),
		"deaths": level.deaths,
	}
	entry.merge(data)
	var file := _open()
	if file:
		file.store_line(JSON.stringify(entry))
		file.close()


static func _open() -> FileAccess:
	if _path == "":
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
		var stamp := Time.get_datetime_string_from_system(true).replace(":", "-")
		_path = "%s/%s_%d.jsonl" % [dir, stamp, OS.get_process_id()]
	var file := FileAccess.open(_path, FileAccess.READ_WRITE if FileAccess.file_exists(_path) else FileAccess.WRITE)
	if file:
		file.seek_end()
	return file


## Best guess at what killed a player: the nearest hazard, enemy or scissor.
static func death_cause(player: Player, room: Node) -> String:
	var best := "fall"
	var best_d := 96.0
	var stack: Array[Node] = [room]
	while stack:
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		if not (node is Hazard or node is ClipperBot or node is BarberBot or node is Scissor):
			continue
		var d := (node as Node2D).global_position.distance_to(player.global_position)
		if node is Hazard:
			# Pools and irons are wide: measure to their rectangle, not their corner.
			var rect := Rect2((node as Node2D).global_position, node.get("size") if node.get("size") != null else Vector2.ZERO)
			d = rect.grow(1.0).get_center().distance_to(player.global_position) if rect.size == Vector2.ZERO else _rect_distance(rect, player.global_position)
		if d < best_d:
			best_d = d
			best = "Scissor" if node is Scissor else String(node.name)
	return best


static func _rect_distance(rect: Rect2, p: Vector2) -> float:
	var q := Vector2(clampf(p.x, rect.position.x, rect.end.x), clampf(p.y, rect.position.y, rect.end.y))
	return q.distance_to(p)
