extends PlayBot
## Runtime regression for retiring the extra styles: chair button wiring and damaging
## boss scissors must preserve the two friends, their health and their chosen roles.
const Finale := preload("res://scenes/levels/level_06.tscn")

func _run() -> void:
	await load_level(Finale, 3)
	var chair: Area2D = level.rooms[3].get_node("StylingStation")
	level.open_styling(chair)
	check(paused and level.styling_menu.visible, "finale chair opens safely")
	check(level.styling_menu._options.size() == 4 and level.styling_menu._portraits.size() == 2, "chair exposes two familiar choices per friend")
	level.styling_menu._options[0].pressed.emit()
	check(level.styling_menu._confirm.disabled, "chair prevents giving both friends the same haircut")
	level.styling_menu._options[3].pressed.emit()
	level.styling_menu._confirm.pressed.emit()
	await _ticks(3)
	check(not paused and p1.hair == Player.Hair.TWIN_TAILS and p2.hair == Player.Hair.POMPADOUR, "both chair buttons apply the selected pair with the two-style layout")
	p1._invincible = 0
	var shot := Scissor.new()
	shot.position = Vector2(-600, -100)
	shot.restyles = true
	level.rooms[3].add_child(shot)
	shot._on_body_entered(p1)
	await _ticks(3)
	check(p1.hp == 2 and p2.hp == 3, "damaging assistant scissors hurt only the struck friend")
	check(p1.hair == Player.Hair.POMPADOUR and p2.hair == Player.Hair.TWIN_TAILS, "assistant scissors swap only the original two haircuts")
	check(p1.ability.display_name == "Pompadour" and p2.ability.display_name == "Twin-Tails", "portraits and abilities follow the swapped roles")
	level.restart_room()
	await _ticks(20)
	check(p1.hair == Player.Hair.TWIN_TAILS and p2.hair == Player.Hair.POMPADOUR, "restart restores the saved chair pair after a forced swap")
	finish()
