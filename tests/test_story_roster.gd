extends PlayBot
## Damaging boss scissors preserve the original pair; room restarts restore authored roles.
const Finale := preload("res://scenes/levels/level_06.tscn")

func _run() -> void:
	await load_level(Finale, 3)
	check(not level.rooms[3].has_node("StylingStation"), "no spawn chair in the finale")
	check(p1.hair == Player.Hair.POMPADOUR and p2.hair == Player.Hair.TWIN_TAILS, "finale starts with its authored roles")
	p1._invincible = 0
	var shot := Scissor.new()
	shot.position = Vector2(-600, -100)
	shot.restyles = true
	level.rooms[3].add_child(shot)
	shot._on_body_entered(p1)
	await _ticks(3)
	check(p1.hp == 2 and p2.hp == 3, "damaging assistant scissors hurt only the struck friend")
	check(p1.hair == Player.Hair.TWIN_TAILS and p2.hair == Player.Hair.POMPADOUR, "assistant scissors swap only the original two haircuts")
	check(p1.ability.display_name == "Twin-Tails" and p2.ability.display_name == "Pompadour", "portraits and abilities follow the swapped roles")
	level.restart_room()
	await _ticks(20)
	check(p1.hair == Player.Hair.POMPADOUR and p2.hair == Player.Hair.TWIN_TAILS, "restart restores authored roles after a forced swap")
	finish()
