extends PlayBot
## Every campaign chair must restore both players to safe authored ground, including
## the Extensions tower and the finale's timed flat iron. Uses an isolated test save.

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
			var chair: Area2D = room.get_node("StylingStation")
			level.open_styling(chair)
			check(paused and level.styling_menu.visible, label + ": chair reachable from both starts")
			if not paused:
				continue
			level.styling_menu.choose(0, p2.hair)
			level.styling_menu.choose(1, p1.hair)
			level.styling_menu.commit()
			var pair := [p1.hair, p2.hair]
			level.restart_room()
			# Wait beyond a complete hot-iron cycle; spawn invulnerability doesn't
			# protect against lethal hazard Areas or being embedded in a tower.
			await _ticks(240)
			check(p1.alive and p2.alive and level.deaths == 0 and not paused, label + ": checkpoint survives idle restart")
			check(p1.is_on_floor() and p2.is_on_floor() and p1.hair == pair[0] and p2.hair == pair[1], label + ": chosen pair lands on safe ground")
	finish()
