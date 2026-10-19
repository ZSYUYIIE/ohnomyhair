extends SceneTree
## Gate check: every room of the escape campaign is solvable by every
## haircut pair it allows. A room lists its obstacles as gates (each passable with any one
## of a few verbs, StyleRules) and its story haircut set; every distinct pair from that set
## must have a verb for every gate. This is the design contract behind the bot playthroughs:
## the bots prove one pair can do it, this proves no allowed pair is locked out.
## Run: godot --headless --path . --script res://tests/test_gates.gd

var passed := 0
var failed := 0


func _initialize() -> void:
	var paths: Array[String] = []
	for entry in Progress.LEVELS:
		paths.append(entry.path)
	for path in paths:
		var level: Level = load(path).instantiate()
		for room: Room in level.get_node("Rooms").get_children():
			_check_room(path.get_file().get_basename(), room)
		level.free()
	_unit_rules()
	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _check_room(level_name: String, room: Room) -> void:
	var where := "%s %s" % [level_name, room.title]
	check(room.gates.size() > 0, "%s: lists its gates" % where)
	check(room.starting_hair.size() == 2 and room.starting_hair[0] != room.starting_hair[1], "%s: starts with two different haircuts" % where)
	check(room.styles.size() >= 2 and room.starting_hair[0] in room.styles and room.starting_hair[1] in room.styles,
		"%s: its starting pair belongs to the story haircut set" % where)
	check(room.styles.size() == 2 and StyleRules.TT in room.styles and StyleRules.POMP in room.styles,
		"%s: the story stays with Twin-Tails and Pompadour" % where)
	for pair in StyleRules.pairs(room.styles):
		var blocked := StyleRules.blocked_gates(pair, room.gates)
		check(blocked.is_empty(), "%s: %s + %s can pass every gate%s" % [where, StyleRules.hair_name(pair[0]),
			StyleRules.hair_name(pair[1]), "" if blocked.is_empty() else "  (blocked: %s)" % ", ".join(blocked)])
	for gate in room.gates:
		for verb in gate.any:
			check(StyleRules.VERB_INFO.has(verb), "%s: gate '%s' uses a known verb (%s)" % [where, gate.name, verb])


func _unit_rules() -> void:
	var two := PackedInt32Array([StyleRules.TT, StyleRules.POMP])
	check(StyleRules.pairs(two).size() == 1, "the two story haircuts make one distinct pair")
	check(Player.HAIR_INFO.size() == 2 and Player.HAIR_SCRIPTS.size() == 2, "only the original two haircuts are playable")
	check("sling" in StyleRules.verbs([StyleRules.TT, StyleRules.POMP]) and not "sling" in StyleRules.verbs([StyleRules.TT]), "sling needs both friends")
	check(StyleRules.next_style(StyleRules.TT, StyleRules.POMP, two) == -1, "with only the pair allowed there is nothing new: the friends swap")


func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("  ok   ", label)
	else:
		failed += 1
		push_error("FAIL " + label)
		print("  FAIL ", label)
