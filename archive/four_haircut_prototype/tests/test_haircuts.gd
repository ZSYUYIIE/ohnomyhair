extends PlayBot
## Actual input and collision tests for the four-haircut expansion.
const PlayerScene := preload("res://scenes/player/player.tscn")
const Lab := preload("res://scenes/levels/style_lab.tscn")
const Anchor := preload("res://scenes/props/hair_anchor.gd")
var arena: Node2D

func _run() -> void:
	await _shield_and_water()
	await _bounce_and_cannonball()
	await _double_parry()
	await _rope_and_hook()
	await _lasso()
	await _restyling()
	await _chairs_and_restart()
	finish()

func _arena(hair1: Player.Hair, hair2 := Player.Hair.TWIN_TAILS) -> void:
	for action in InputMap.get_actions(): Input.action_release(action)
	paused = false
	Engine.time_scale = 1
	if is_instance_valid(arena): arena.queue_free()
	if is_instance_valid(level):
		level.queue_free()
		level = null
	await _ticks(3)
	arena = Node2D.new()
	root.add_child(arena)
	_box(Rect2(-1000, 0, 3000, 64))
	p1 = _player(1, hair1, Vector2(0, -22))
	p2 = _player(2, hair2, Vector2(-240, -22))
	await _ticks(15)
	p1._invincible = 0
	p2._invincible = 0

func _box(rect: Rect2) -> StaticBody2D:
	var box := StaticBody2D.new()
	box.collision_layer = Layers.WORLD
	box.position = rect.position
	Player.add_rect_shape(box, rect.size, rect.size / 2)
	arena.add_child(box)
	return box

func _player(id: int, style: Player.Hair, at: Vector2) -> Player:
	var p: Player = PlayerScene.instantiate()
	p.player_id = id
	p.hair = style
	p.position = at
	arena.add_child(p)
	return p

func _shield_and_water() -> void:
	await _arena(Player.Hair.AFRO)
	check(p1.sprite.sprite_frames.has_animation("guard"), "Afro has its own usable sprite frames")
	hold(p1, "attack", true)
	await _ticks(2)
	p1.take_hit(1)
	check(p1.hp == 3, "Afro shields an incoming hit")
	await _ticks(60)
	p1._invincible = 0
	p1.take_hit(1)
	check(p1.hp == 2, "shield expires instead of providing permanent immunity")
	hold(p1, "attack", false)
	await _ticks(30)
	p1.soak(5)
	hold(p1, "attack", true)
	await _ticks(2)
	p1._invincible = 0
	p1.take_hit(1)
	check(p1.hp == 1, "wet Afro cannot shield")
	hold(p1, "skill", true)
	await _ticks(40)
	check(p1.ability.charge == 0, "wet Afro cannot charge a spring")
	p1.dry()
	await _ticks(30)
	check(p1.ability.charge > 0.2, "drying restores the Afro spring")

func _bounce_and_cannonball() -> void:
	await _arena(Player.Hair.AFRO)
	p2.respawn_at(Vector2(0, -66))
	await _ticks(15)
	hold(p1, "skill", true)
	await _ticks(40)
	hold(p1, "skill", false)
	await _ticks(3)
	check(p2.velocity.y < -900 and p2.global_position.y < -66, "charged Afro spring launches a teammate above ordinary jump height")
	await _arena(Player.Hair.AFRO, Player.Hair.POMPADOUR)
	var gel: BreakableWall = load("res://scenes/props/breakable_wall.tscn").instantiate()
	gel.position = Vector2(160, -300)
	gel.size = Vector2(64, 300)
	gel.requires_cannonball = true
	gel.regrow_time = 10
	arena.add_child(gel)
	p2.respawn_at(Vector2(90, -22))
	await _ticks(15)
	await tap(p2, "skill")
	await _ticks(20)
	check(gel.is_solid(), "a solo pompadour dash cannot break reinforced gel")
	p2.respawn_at(Vector2(0, -66))
	await _ticks(15)
	hold(p1, "skill", true)
	await _ticks(35)
	hold(p2, "skill", true)
	await _ticks(2)
	check(p2.ability._dash_left <= 0, "Pompadour holds position while arming the spring combo")
	hold(p1, "skill", false)
	await _ticks(28)
	check(not gel.is_solid() and p2.global_position.x > 224, "co-op cannonball punches through reinforced gel")

func _double_parry() -> void:
	await _arena(Player.Hair.AFRO)
	hold(p1, "attack", true)
	await _ticks(2)
	var blue := Scissor.new()
	blue.position = Vector2(-35, -44)
	blue.direction = Vector2.RIGHT
	arena.add_child(blue)
	blue.deflect()
	await _ticks(3)
	check(is_instance_valid(blue) and blue.holder == p1, "Afro catches a teammate's parried scissor")
	hold(p1, "attack", false)
	await _ticks(3)
	check(is_instance_valid(blue) and blue.holder == null and blue.golden and blue.direction == Vector2.RIGHT, "releasing Afro attack returns a golden scissor toward the enemy")

func _rope_and_hook() -> void:
	await _arena(Player.Hair.LONG_STRAIGHT)
	_box(Rect2(-100, -240, 110, 32))
	p1.respawn_at(Vector2(0, -262))
	p2.respawn_at(Vector2(36, -22))
	await _ticks(15)
	hold(p1, "skill", true)
	hold(p2, "jump", true)
	await _ticks(10)
	check(p2.rope_provider == p1, "friend holding jump can grab the hanging hair rope")
	await _ticks(45)
	check(p2.global_position.y < -150, "friend climbs a real ledge using the hair rope")
	hold(p2, "right", true)
	await _ticks(3)
	check(p2.rope_provider == null and p2.velocity.x > 100, "sideways release boosts the rider off the rope")
	await _arena(Player.Hair.LONG_STRAIGHT)
	var ring := Anchor.new()
	ring.position = Vector2(160, -180)
	arena.add_child(ring)
	hold(p1, "jump", true)
	await _ticks(6)
	hold(p1, "skill", true)
	await _ticks(24)
	check(p1.global_position.x > 120 and p1.global_position.y < -120, "airborne Long Straight Hair grapples to a gold ring")
	await _arena(Player.Hair.LONG_STRAIGHT)
	ring = Anchor.new()
	ring.position = Vector2(160, -180)
	arena.add_child(ring)
	_box(Rect2(60, -600, 32, 600))
	hold(p1, "jump", true)
	await _ticks(6)
	hold(p1, "skill", true)
	await _ticks(30)
	check(p1.global_position.x < 40 and not p1.ability.is_driving(), "hook cannot travel through a solid wall")

func _lasso() -> void:
	await _arena(Player.Hair.LONG_STRAIGHT)
	var bot := ClipperBot.new()
	bot.position = Vector2(160, 0)
	bot.speed = 0
	arena.add_child(bot)
	await _ticks(5)
	await tap(p1, "attack")
	await _ticks(15)
	check(bot.global_position.x < 120 and bot.stun > 0, "lasso pulls and stuns a light enemy")
	bot.queue_free()
	await _ticks(40)
	var lever: Lever = load("res://scenes/props/lever.tscn").instantiate()
	lever.position = Vector2(150, -30)
	arena.add_child(lever)
	await _ticks(5)
	await tap(p1, "attack")
	check(lever.is_on, "lasso remotely pulls a visible lever")

func _restyling() -> void:
	await _arena(Player.Hair.POMPADOUR)
	var shot := Scissor.new()
	shot.position = Vector2(-600, -30)
	shot.restyles = true
	arena.add_child(shot)
	shot._on_body_entered(p1)
	await _ticks(3)
	check(p1.hp == 2 and p1.hair == Player.Hair.AFRO, "Tony's damaging scissors change the haircut without healing")
	p1._invincible = 0
	hold(p1, "attack", true)
	await _ticks(2)
	shot = Scissor.new()
	shot.position = Vector2(-600, -30)
	shot.restyles = true
	arena.add_child(shot)
	shot._on_body_entered(p1)
	await _ticks(3)
	check(p1.hp == 2 and p1.hair == Player.Hair.AFRO, "shielding Tony's scissors prevents both damage and forced restyling")
	p1.set_hair(Player.Hair.LONG_STRAIGHT)
	p1.hp = 1
	p1.restyle_next()
	# The friend wears twin-tails, so the wrap skips it: two friends never share a haircut.
	check(p1.hair == Player.Hair.POMPADOUR and p1.hp == 1, "haircut cycle wraps around, skips the friend's haircut and keeps HP")
	p1.grab(p2)
	p1.set_hair(Player.Hair.AFRO)
	check(p1.carrying == null and p2.carried_by == null, "changing haircut safely releases a carried friend")
	p2.set_hair(Player.Hair.LONG_STRAIGHT)
	var swap: HairSwapChair = load("res://scenes/props/hair_swap_chair.tscn").instantiate()
	swap.position = Vector2(1000, -128)
	arena.add_child(swap)
	swap._swap()
	check(p1.hair == Player.Hair.LONG_STRAIGHT and p2.hair == Player.Hair.AFRO, "the surprise chair swaps the actual pair even with new haircuts")

func _chairs_and_restart() -> void:
	for action in InputMap.get_actions(): Input.action_release(action)
	arena.queue_free()
	await _ticks(3)
	await load_level(Lab)
	check(p1.hair == Player.Hair.AFRO and p2.hair == Player.Hair.POMPADOUR, "Style Lab starts with the taught pair")
	var chair: Area2D = level.rooms[0].get_node("StylingStation")
	await tap(p2, "down")
	await _ticks(4)
	check(paused and level.styling_menu.visible, "nearby friends can open the styling station safely paused")
	# The Bounce Studio's chair only offers its own pair (Afro, Pompadour).
	check(level.styling_menu._options[3].disabled and not level.styling_menu._options[1].disabled, "the chair greys out haircuts this room doesn't allow")
	level.styling_menu._options[3].pressed.emit()
	check(level.styling_menu.selections[0] == Player.Hair.AFRO, "a disallowed haircut can't be picked")
	level.styling_menu._options[1].pressed.emit()
	check(level.styling_menu._confirm.disabled, "two friends can't confirm the same haircut")
	level.styling_menu._options[6].pressed.emit()
	check(p1.hair == Player.Hair.AFRO, "selection previews do not apply before confirmation")
	level.styling_menu._confirm.pressed.emit()
	await _ticks(3)
	check(not paused and p1.hair == Player.Hair.POMPADOUR and p2.hair == Player.Hair.AFRO, "confirm applies both styles (roles swapped) and resumes")
	level.restart_room()
	await _ticks(15)
	check(p1.hair == Player.Hair.POMPADOUR and p2.hair == Player.Hair.AFRO and p1.is_on_floor() and p2.is_on_floor(), "room restart restores chosen checkpoint styles on safe ground")
	check(level.get_node("Rooms/Room1/ReinforcedGel").is_solid(), "styling checkpoint still rebuilds the room's puzzle state")
	chair = level.rooms[0].get_node("StylingStation")
	level.open_styling(chair)
	level.styling_menu.choose(0, Player.Hair.TWIN_TAILS)
	await press_action("ui_cancel")
	check(not paused and p1.hair == Player.Hair.POMPADOUR, "cancel leaves the current styles and checkpoint unchanged")
	p1.die()
	check(await choose_on_death("Restart room"), "death after styling opens the restart menu")
	check(level.deaths == 1 and p1.hair == Player.Hair.POMPADOUR and p2.hair == Player.Hair.AFRO, "death restart retains the chosen pair and counts the death")
	chair = level.rooms[0].get_node("StylingStation")
	p2.global_position.x += 400
	level.open_styling(chair)
	check(not paused and not level.styling_menu.visible, "both friends must be near the chair")
