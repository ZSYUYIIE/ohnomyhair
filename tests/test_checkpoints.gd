extends PlayBot
## Every room restart must restore both players to safe authored ground, including
## the finale's timed flat iron. Uses an isolated test save.

func _run() -> void:
	for chapter in Progress.LEVELS:
		var scene: PackedScene = load(chapter.path)
		var probe: Level = scene.instantiate()
		var count := probe.get_node("Rooms").get_child_count()
		probe.free()
		for index in count:
			await load_level(scene, index)
			var room := level.rooms[index]
			var label := "%s / %s" % [chapter.title, room.title]
			check(not room.has_node("StylingStation"), label + ": no extra spawn-point chair")
			var pair := [p1.hair, p2.hair]
			# A forced swap mid-room must not change the authored restart pair.
			p1.set_hair(pair[1])
			p2.set_hair(pair[0])
			level.restart_room()
			# Wait beyond a complete hot-iron cycle; spawn invulnerability doesn't
			# protect against lethal hazard Areas or being embedded in a tower.
			await _ticks(240)
			check(p1.alive and p2.alive and level.deaths == 0 and not paused, label + ": checkpoint survives idle restart")
			check(p1.is_on_floor() and p2.is_on_floor() and p1.hair == pair[0] and p2.hair == pair[1], label + ": authored pair lands on safe ground")
	finish()
