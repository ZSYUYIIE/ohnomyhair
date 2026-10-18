class_name PlayBot
extends SceneTree
## Base for level playthrough tests: simulated input for both players plus a
## pass/fail counter. A test extends this, loads its level in _run() and ends
## with finish().

const TILE := 32.0
## Sloppy-player mode (tools/difficulty/sweep.py sets SLOPPY=1 and SEED=n): the same
## playthrough, played like a person. After every cue the bot waits for (a shower
## stopping, a scissor arriving...) it reacts 130-330 ms late; it aims for spots a little
## off (6 px); and it holds buttons a little too long or short. Failing more often under this is
## a sign a step asks for frame-perfect play.
const REACTION_FRAMES := Vector2i(8, 20)
const AIM_JITTER := 6.0
const HOLD_JITTER := 0.25
const CUE_WAIT_FRAMES := 45

var sloppy := OS.get_environment("SLOPPY") == "1"
var rng := RandomNumberGenerator.new()

var passed := 0
var failed := 0
var level: Level
var p1: Player
var p2: Player


func _initialize() -> void:
	# Level clears record best times: keep them out of the player's real save.
	Progress.save_path = "user://test_progress.cfg"
	Progress.reset()
	# Bot runs log to their own folder, so they never mix with real play sessions.
	Telemetry.dir = "user://telemetry_bots"
	Telemetry.source = "bot-sloppy" if sloppy else "bot"
	Telemetry.enabled = sloppy or OS.get_environment("BOT_TELEMETRY") == "1"
	var seed_text := OS.get_environment("SEED")
	if seed_text != "":
		rng.seed = seed_text.to_int()
	else:
		rng.randomize()
	_run.call_deferred()


## Override: the playthrough.
func _run() -> void:
	pass


func load_level(scene: PackedScene, start_room := 0) -> void:
	if level:
		level.queue_free()
		await _ticks(2)
	paused = false   # a previous level may have left its results menu up
	_follow(scene.instantiate())
	level.start_room = start_room
	root.add_child(level)
	await _ticks(20)


## Restarting a room swaps the Level node for a fresh copy: keep pointing at the live one.
func _follow(fresh: Level) -> void:
	level = fresh
	p1 = level.get_node("Players/P1")
	p2 = level.get_node("Players/P2")
	level.replaced.connect(_follow)


## Waits for the death popup, then picks one of its buttons.
func choose_on_death(button: String) -> bool:
	var shown := await wait_until(func(): return level.menu.is_open(), 120)
	if shown:
		level.menu.press(button)
		await _ticks(10)
	return shown


## Fire an input action as a key press (for Esc / R, which go through _unhandled_input).
func press_action(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await physics_frame
	ev = ev.duplicate()
	ev.pressed = false
	Input.parse_input_event(ev)
	await _ticks(2)


func finish() -> void:
	for action in InputMap.get_actions():
		Input.action_release(action)
	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


## Both walk into the room's exit and wait for the pan to room `next_index`.
func enter_exit(room: Node, next_index: int) -> void:
	var exit_x: float = room.get_node("Exit").global_position.x
	await walk_to(p2, exit_x + 48)
	await walk_to(p1, exit_x + 16)
	var moved := await wait_until(func(): return level.room_index == next_index and not level._busy, 180)
	check(moved, "room %d: both in the exit pans to the next room" % next_index)
	await _ticks(10)


# --- Bot helpers --------------------------------------------------------------

func hold(p: Player, action: String, on: bool) -> void:
	var name := "p%d_%s" % [p.player_id, action]
	if on:
		Input.action_press(name)
	else:
		Input.action_release(name)


func tap(p: Player, action: String) -> void:
	hold(p, action, true)
	await physics_frame
	hold(p, action, false)
	await physics_frame


func _ticks(n: int) -> void:
	if sloppy:
		n = maxi(1, roundi(n * rng.randf_range(1.0 - HOLD_JITTER, 1.0 + HOLD_JITTER)))
	for i in n:
		await physics_frame


func wait_until(cond: Callable, max_ticks: int) -> bool:
	for i in max_ticks:
		if cond.call():
			# Only a wait for something OUTSIDE the player's control (a timer, an enemy,
			# a shower) gets a reaction delay. Short waits are the bot steering its own
			# move, which a person does continuously, not by reacting late.
			if i >= CUE_WAIT_FRAMES:
				await _react()
			return true
		await physics_frame
	return cond.call()


## Twin-tails holds skill to grab `friend`, the way a person does: if the friend isn't in
## reach (a step too far, or on a different step), shuffle to just beside them and try
## again. Leaves skill held on success, like the single-press grab it replaces.
func grab(carrier: Player, friend: Player, tries := 4) -> bool:
	for attempt in tries:
		hold(carrier, "skill", true)
		for i in 2:
			await physics_frame
		if carrier.carrying == friend:
			return true
		hold(carrier, "skill", false)
		await physics_frame
		var side := -1.0 if carrier.global_position.x < friend.global_position.x else 1.0
		if absf(carrier.global_position.y - friend.global_position.y) >= Player.HALF_SIZE.y:
			# Perched on the friend's head (or a step above): step off first.
			await walk_to(carrier, friend.global_position.x + side * 64.0, 120, false)
		await walk_to(carrier, friend.global_position.x + side * 30.0, 120, false)
	return false


## Call before counter-checks (a solo jump into the dye on purpose, a forced death to test
## the popup, boss unit checks): they test rules, not a person's timing, so they run
## exactly, and their deaths must not count in the play log.
func begin_counter_checks() -> void:
	Telemetry.enabled = false
	sloppy = false


## A person notices a cue a moment after it happens.
func _react() -> void:
	if sloppy:
		for i in rng.randi_range(REACTION_FRAMES.x, REACTION_FRAMES.y):
			await physics_frame


## Walk toward x, hopping up any step in the way. Local x is in level space.
## Stops when the level gets busy (room cleared / pan): the target belongs to the old
## room, and walking on would steer the player around the next one.
func walk_to(p: Player, x: float, max_ticks := 600, aim_error := true) -> void:
	var start_room := level.room_index if is_instance_valid(level) else -1
	if sloppy and aim_error:
		x += rng.randf_range(-AIM_JITTER, AIM_JITTER)
	for i in max_ticks:
		# Stop once the level is busy (clear / pan) or has moved on: the target point
		# belongs to the old room, and steering back would walk around the next one.
		if is_instance_valid(level) and (level._busy or level.room_index != start_room):
			break
		var dx := x - p.global_position.x
		if absf(dx) < 6.0:
			break
		hold(p, "right", dx > 0.0)
		hold(p, "left", dx < 0.0)
		if p.is_on_floor() and p.is_on_wall():
			# Hold jump for the full arc; a 1-frame tap is a short hop (variable jump).
			hold(p, "jump", true)
			await _ticks(18)
			hold(p, "jump", false)
		else:
			await physics_frame
	hold(p, "right", false)
	hold(p, "left", false)
	await wait_until(func(): return p.is_on_floor() and absf(p.velocity.x) < 1.0, 60)


## Run right, jump at take_off_x holding jump + skill (glide), land past land_x.
## jump_frames > 0 releases jump after that many frames (a tap); otherwise it's held.
func glide_jump(p: Player, take_off_x: float, land_x: float, release_skill := true, jump_frames := -1) -> bool:
	hold(p, "skill", true)
	hold(p, "right", true)
	var jumped := false
	for i in 400:
		await physics_frame
		if not jumped and p.global_position.x >= take_off_x:
			hold(p, "jump", true)
			jumped = true
		elif jumped and jump_frames > 0:
			jump_frames -= 1
			if jump_frames == 0:
				hold(p, "jump", false)
		elif jumped and p.is_on_floor() and p.global_position.x > land_x:
			break
	hold(p, "right", false)
	hold(p, "jump", false)
	if release_skill:
		hold(p, "skill", false)
	await _ticks(10)
	return p.alive and p.is_on_floor() and p.global_position.x > land_x


func climb_onto_head(rider: Player, base: Player) -> bool:
	await walk_to(rider, base.global_position.x - 70.0)
	hold(rider, "right", true)
	hold(rider, "jump", true)
	await wait_until(func(): return rider.global_position.x >= base.global_position.x - 14.0, 60)
	hold(rider, "right", false)
	hold(rider, "jump", false)
	await wait_until(func(): return rider.is_on_floor(), 60)
	await _ticks(5)
	return rider.global_position.y < base.global_position.y - 30.0


## Base presses skill to launch the rider, who steers right and stops near stop_x.
func launch_onto(rider: Player, base: Player, stop_x: float) -> void:
	await tap(base, "skill")
	hold(rider, "right", true)
	await wait_until(func(): return rider.global_position.x >= stop_x - 20.0, 120)
	hold(rider, "right", false)
	await wait_until(func(): return rider.is_on_floor(), 120)
	await walk_to(rider, stop_x)


# --- Combat / combo helpers ------------------------------------------------------

## Face and parry the next incoming enemy scissor. True if one got deflected.
func parry_next_scissor(p: Player, max_ticks: int) -> bool:
	for i in max_ticks:
		var s := _incoming(p)
		if s:
			_face(p, s.global_position.x)
			await tap(p, "attack")
			return s.deflected
		await physics_frame
	return false


## What a sensible P2 does before a carry: parry whatever comes, and go once the
## turret is jammed and no enemy scissor is still in flight.
func wait_for_clear_window(parrier: Player, turret: ScissorTurret, max_ticks: int) -> bool:
	for i in max_ticks:
		var s := _incoming(parrier)
		if s:
			_face(parrier, s.global_position.x)
			await tap(parrier, "attack")
			continue
		var in_flight := get_nodes_in_group("scissors").any(func(x): return not x.deflected)
		if turret._jam > 1.5 and not in_flight:
			return true
		await physics_frame
	return false


## Walk up to a clipper bot and dash into it until it's gone.
func smash_bot(p: Player, bot: ClipperBot) -> bool:
	for attempt in 12:
		if not is_instance_valid(bot):
			return true
		# Dash from range (a dash covers ~5 tiles) instead of walking into its blades.
		var side := signf(p.global_position.x - bot.global_position.x)
		await walk_to(p, bot.global_position.x + side * 120.0, 120)
		if not is_instance_valid(bot):
			return true
		_face(p, bot.global_position.x)
		await tap(p, "skill")
		await _ticks(30)
	return not is_instance_valid(bot)


## An enemy scissor about to enter p's parry range from either side.
func _incoming(p: Player) -> Scissor:
	for s: Scissor in get_nodes_in_group("scissors"):
		var dx := s.global_position.x - p.global_position.x
		var dy := absf(s.global_position.y - p.global_position.y)
		if not s.deflected and dy < 24.0 and signf(dx) == -signf(s.direction.x) and absf(dx) < 44.0:
			return s
	return null


func _face(p: Player, x: float) -> void:
	p.facing = signf(x - p.global_position.x)
	p.visual.scale.x = p.facing
	p.hit_box.position.x = absf(p.hit_box.position.x) * p.facing


## Hair Catch: twin-tails holds skill (pigtails open) until a parried (blue) scissor is
## caught, then lets go to toss it straight up. True if it went up golden.
func catch_and_toss(p: Player, max_ticks: int) -> bool:
	hold(p, "skill", true)
	var caught := await wait_until(func(): return p.ability.is_holding_scissor(), max_ticks)
	await _ticks(4)
	var s: Scissor = null
	for x: Scissor in get_nodes_in_group("scissors"):
		if x.holder == p:
			s = x
	hold(p, "skill", false)
	await _ticks(2)
	return caught and s != null and is_instance_valid(s) and s.golden and s.direction == Vector2.UP


## `guard` parries anything coming at them until `done` returns true (run another
## player's moves in parallel by starting them without await).
func guard_until(guard: Player, done: Callable, max_ticks: int) -> bool:
	for i in max_ticks:
		if done.call():
			return true
		var s := _incoming(guard)
		if s:
			_face(guard, s.global_position.x)
			await tap(guard, "attack")
		else:
			await physics_frame
	return done.call()


## Full-height jump straight up (onto a shelf above), then wait to land.
func jump_up(p: Player) -> void:
	hold(p, "jump", true)
	await _ticks(20)
	hold(p, "jump", false)
	await wait_until(func(): return p.is_on_floor(), 90)
	await _ticks(5)


func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("  ok   ", label)
	else:
		failed += 1
		push_error("FAIL " + label)
		print("  FAIL ", label, "   p1=", p1.global_position, " p2=", p2.global_position)
