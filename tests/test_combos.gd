extends SceneTree
## Hair-combo checks in a bare arena: each combo works with both friends, and the
## single-player shortcut it is meant to replace does not.
## Run: godot --headless --fixed-fps 60 --path . --script res://tests/test_combos.gd

const TILE := 32.0
const PlayerScene := preload("res://scenes/player/player.tscn")
const WallScene := preload("res://scenes/props/breakable_wall.tscn")
const HazardScene := preload("res://scenes/props/hazard.tscn")

var passed := 0
var failed := 0
var _arena: Node2D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _sling_dash_flings_through_regrowing_gel()
	await _gel_regrows_after_a_solo_smash()
	await _catch_needs_a_parry_first()
	await _catch_reaches_over_the_head()
	await _skill_with_a_friend_on_your_head_never_grabs()
	await _sling_from_low_carry_does_not_clip()
	await _hit_stop_survives_its_caller()
	await _respawn_out_of_a_hazard_dies_once()
	await _golden_scissor_dazes_the_boss_longer()
	await _dryer_lifts_a_glider()
	await _dryer_lifts_a_carry_slower()
	await _hair_copter_lifts_the_rider()
	await _shower_soaks_and_dryer_dries()
	await _wet_pompadour_bounces_off_gel()
	await _tonic_grows_hair_back()
	await _one_air_dash_per_jump()
	await _running_shower_beats_the_dryer()
	await _hot_iron_burns_a_heart_not_a_life()
	for action in InputMap.get_actions():
		Input.action_release(action)
	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


# --- Sling dash ---------------------------------------------------------------

func _sling_dash_flings_through_regrowing_gel() -> void:
	_new_arena()
	_box(Rect2(-2000, 0, 2000, 64))                 # take-off floor, top at y=0
	var wall := _gel(Rect2(9 * TILE, -10 * TILE, 2 * TILE, 9 * TILE), 2.0)
	var a := _spawn(1, Player.Hair.TWIN_TAILS, Vector2(-300, 0))
	var b := _spawn(2, Player.Hair.POMPADOUR, Vector2(-270, 0))
	await _ticks(10)
	_hold(a, "skill", true)
	await _ticks(2)
	_check(a.carrying == b, "sling: twin-tails grabs pompadour")
	_hold(a, "right", true)
	await _wait(func(): return a.global_position.x > 0.0, 120)
	_hold(a, "jump", true)
	await _wait(func(): return a.global_position.x > 6 * TILE, 120)
	await _tap(b, "skill")
	_check(b.carried_by == null and a.carrying == null, "sling: pompadour lets go when she presses skill")
	_check(a.velocity.y < 0.0, "sling: the carrier bobs up when the weight comes off")
	var y0 := b.global_position.y
	await _wait(func(): return not b.ability.is_slinging(), 60)
	_check(b.global_position.x > 11 * TILE, "sling: pompadour punches through the gel curtain (x=%.0f)" % b.global_position.x)
	_check(absf(b.global_position.y - y0) < 4.0, "sling: the fling is flat (no gravity)")
	_hold(a, "right", false)
	_hold(a, "jump", false)
	_hold(a, "skill", false)
	await _ticks(150)
	_check(wall.is_solid(), "sling: the gel grows back afterwards")


## A solo smash leaves the gel open for only regrow_time: walking up later is blocked.
func _gel_regrows_after_a_solo_smash() -> void:
	_new_arena()
	_box(Rect2(-2000, 0, 4000, 64))
	var wall := _gel(Rect2(4 * TILE, -5 * TILE, 2 * TILE, 5 * TILE), 2.0)
	var b := _spawn(2, Player.Hair.POMPADOUR, Vector2(2 * TILE, 0))
	var a := _spawn(1, Player.Hair.TWIN_TAILS, Vector2(-10 * TILE, 0))
	await _ticks(10)
	await _tap(b, "skill")
	await _ticks(10)
	_check(not wall.is_solid(), "gel: a dash smashes it")
	_check(b.global_position.x < 4 * TILE, "gel: a ground dash stops at the wall instead of passing through")
	await _ticks(150)
	_check(wall.is_solid(), "gel: it grows back after 2 s")
	_hold(a, "right", true)
	await _ticks(120)
	_hold(a, "right", false)
	_check(a.global_position.x < 4 * TILE, "gel: twin-tails arriving later is blocked")


# --- Hair Catch -----------------------------------------------------------------

## Only pompadour parries: twin-tails' whip leaves scissors alone, and her open
## pigtails only catch a scissor that was already parried (blue).
func _catch_needs_a_parry_first() -> void:
	_new_arena()
	_box(Rect2(-2000, 0, 4000, 64))
	var a := _spawn(1, Player.Hair.TWIN_TAILS, Vector2(0, 0))
	await _ticks(10)
	var parried := _scissor(Vector2(-60, -30), Vector2.RIGHT, true)
	await _tap(a, "attack")
	await _ticks(3)
	_check(is_instance_valid(parried) and not parried.golden and parried.holder == null, "catch: the whip never hits scissors (no parry for twin-tails)")
	parried.queue_free()
	var raw := _scissor(Vector2(60, -30), Vector2.LEFT, false)
	_hold(a, "skill", true)
	await _ticks(20)
	_check(not a.ability.is_holding_scissor() and a.hp < a.max_hp, "catch: an enemy (red) scissor can't be caught - it hurts")
	_hold(a, "skill", false)
	if is_instance_valid(raw):
		raw.queue_free()
	await _ticks(50)
	var blue := _scissor(Vector2(-90, -30), Vector2.RIGHT, true)
	_hold(a, "skill", true)
	await _wait(func(): return a.ability.is_holding_scissor(), 40)
	_check(is_instance_valid(blue) and blue.holder == a, "catch: holding skill catches a parried (blue) scissor")
	await _ticks(20)
	_check(is_instance_valid(blue) and blue.holder == a and blue.global_position.y < a.global_position.y, "catch: she holds it above her head")
	_hold(a, "skill", false)
	await _ticks(2)
	_check(is_instance_valid(blue) and blue.golden and blue.direction == Vector2.UP, "catch: letting go tosses it straight up, golden")
	# In the air, holding skill is just gliding: a parried scissor flies past.
	await _ticks(30)
	a.global_position = Vector2(0, -6 * TILE)
	_hold(a, "skill", true)
	await _ticks(5)
	var past := _scissor(Vector2(-90, -6 * TILE - 10), Vector2.RIGHT, true)
	await _ticks(25)
	_hold(a, "skill", false)
	_check(not a.ability.is_holding_scissor() and (not is_instance_valid(past) or past.holder == null), "catch: gliding through the air never catches (feet on the ground only)")


## Twin-tails crouching in a trench: enemy scissors pass over her head, and her open
## pigtails still catch the parried one on its way back.
func _catch_reaches_over_the_head() -> void:
	_new_arena()
	_box(Rect2(-2000, 0, 4000, 64))
	var a := _spawn(1, Player.Hair.TWIN_TAILS, Vector2(0, 0))
	var b := _spawn(2, Player.Hair.POMPADOUR, Vector2(-8 * TILE, -2 * TILE))
	_box(Rect2(-12 * TILE, -2 * TILE, 10 * TILE, 2 * TILE))   # pompadour's ledge: 2 tiles up
	await _ticks(10)
	var line_y := b.global_position.y
	var s := _scissor(Vector2(10 * TILE, line_y), Vector2.LEFT, false)
	b.facing = 1.0
	b.visual.scale.x = 1.0
	await _wait(func(): return not is_instance_valid(s) or s.global_position.x - b.global_position.x < 36.0, 300)
	_check(a.hp == a.max_hp, "catch: the enemy scissor flew over twin-tails in the trench")
	await _tap(b, "attack")
	_check(is_instance_valid(s) and s.deflected, "catch: pompadour parries it back")
	_hold(a, "skill", true)
	await _wait(func(): return a.ability.is_holding_scissor(), 120)
	_hold(a, "skill", false)
	await _ticks(2)
	_check(is_instance_valid(s) and s.golden, "catch: twin-tails catches and tosses it up from the trench")


## The way players actually do the hair-copter, in every order: pompadour on twin-tails'
## head (centered or near the edge), then skill before the jump, with it, or a few frames
## into it ("jump, then hold G" - how gliding is taught). It must lift her, never grab her.
## Playtest 3 regression: the old rule grabbed whenever skill came after the jump.
func _skill_with_a_friend_on_your_head_never_grabs() -> void:
	var all_lifted := true
	var none_grabbed := true
	for dx in [0.0, 24.0]:
		for g_delay in [-1, 0, 3, 10]:
			_new_arena()
			_box(Rect2(-2000, 0, 4000, 64))
			_dryer_column()
			var a := _spawn(1, Player.Hair.TWIN_TAILS, Vector2(0, 0))
			var b := _spawn(2, Player.Hair.POMPADOUR, Vector2(dx, -2 * Player.HALF_SIZE.y - 4))
			await _ticks(30)
			if g_delay < 0:
				_hold(a, "skill", true)
				await physics_frame
				_hold(a, "jump", true)
			else:
				_hold(a, "jump", true)
				await _ticks(g_delay)
				_hold(a, "skill", true)
			await _ticks(60)
			_hold(a, "jump", false)
			_hold(a, "skill", false)
			if a.carrying == b:
				none_grabbed = false
			if b.global_position.y > -8 * TILE:
				all_lifted = false
				print("    not lifted: dx=%d skill after %d frames, b.y=%.0f" % [dx, g_delay, b.global_position.y])
	_check(none_grabbed, "hair-copter: skill with a friend on your head never grabs her (any press order)")
	_check(all_lifted, "hair-copter: she's lifted whether she stands centered or near the edge")


## Slinging close above the floor must not push pompadour into the ground.
func _sling_from_low_carry_does_not_clip() -> void:
	_new_arena()
	_box(Rect2(-2000, 0, 4000, 64))
	var a := _spawn(1, Player.Hair.TWIN_TAILS, Vector2(0, 0))
	var b := _spawn(2, Player.Hair.POMPADOUR, Vector2(20, 0))
	await _ticks(10)
	_hold(a, "skill", true)
	await _ticks(2)
	_hold(a, "jump", true)
	await _ticks(3)
	await _tap(b, "skill")
	await _wait(func(): return not b.ability.is_slinging(), 60)
	await _ticks(30)
	_hold(a, "skill", false)
	_hold(a, "jump", false)
	_check(b.is_on_floor() and b.global_position.y <= -Player.HALF_SIZE.y + 1.0, "sling: a low fling lands on the floor, not inside it")


## Regression: freeing the player mid-freeze used to leave the game at 5% speed.
func _hit_stop_survives_its_caller() -> void:
	_new_arena()
	var a := _spawn(1, Player.Hair.TWIN_TAILS, Vector2.ZERO)
	await _ticks(5)
	a.hit_stop(0.05)
	_arena.free()
	_arena = null
	await create_timer(0.3, true, false, true).timeout
	_check(is_equal_approx(Engine.time_scale, 1.0), "hit-stop: time scale recovers even if its player is freed")


## Regression: the hazard's overlap list lagged behind the respawn teleport, so a
## player who died in dye "died" again right after respawning elsewhere.
func _respawn_out_of_a_hazard_dies_once() -> void:
	_new_arena()
	_box(Rect2(-2000, 0, 4000, 64))
	var dye: Hazard = HazardScene.instantiate()
	dye.position = Vector2(200, -40)
	dye.size = Vector2(128, 40)
	_arena.add_child(dye)
	var a := _spawn(1, Player.Hair.TWIN_TAILS, Vector2(260, 0))
	var deaths := [0]
	a.died.connect(func(_p): deaths[0] += 1)
	await _wait(func(): return not a.alive, 30)
	a.respawn_at(Vector2(-300, -Player.HALF_SIZE.y))
	await _ticks(30)
	_check(deaths[0] == 1 and a.alive, "hazard: dying in dye then respawning elsewhere is one death, not two")


func _golden_scissor_dazes_the_boss_longer() -> void:
	_new_arena()
	_box(Rect2(-2000, 0, 4000, 64))
	var boss := BarberBot.new()
	_arena.add_child(boss)
	await _ticks(5)
	boss.take_hit(2, 6.0)
	_check(boss.state == BarberBot.State.DAZED and boss._t > 5.0, "boss: a golden (hair-caught) scissor dazes it for 6 s")


# --- Salon mechanics -----------------------------------------------------------

## Column from y=-12 tiles to the floor, 2 tiles wide, centered on x=0.
func _dryer_column() -> HairDryer:
	var dryer := HairDryer.new()
	dryer.position = Vector2(-TILE, -12 * TILE)
	dryer.size = Vector2(2 * TILE, 12 * TILE)
	_arena.add_child(dryer)
	return dryer


func _dryer_lifts_a_glider() -> void:
	_new_arena()
	_box(Rect2(-2000, 0, 4000, 64))
	_dryer_column()
	var a := _spawn(1, Player.Hair.TWIN_TAILS, Vector2(0, 0))
	await _ticks(10)
	_hold(a, "jump", true)
	_hold(a, "skill", true)
	await _ticks(90)
	_check(a.global_position.y < -9 * TILE, "dryer: a gliding twin-tails rides the warm air up (y=%.0f)" % a.global_position.y)
	await _ticks(60)
	_check(a.global_position.y > -13.5 * TILE and not a.is_on_floor(), "dryer: she bobs at the top of the column instead of flying off")
	_hold(a, "skill", false)
	await _wait(func(): return a.is_on_floor(), 240)
	_hold(a, "jump", false)
	var b := _spawn(2, Player.Hair.POMPADOUR, Vector2(0, -8 * TILE))
	await _ticks(20)
	_check(b.velocity.y <= 262.0, "dryer: a non-glider falls slower in the warm air")


## Playtest 5: players expect the warm air to lift a carry too. It does, at about half
## the solo speed (the friend's weight), so riding on her head stays the fast way up.
func _dryer_lifts_a_carry_slower() -> void:
	_new_arena()
	_box(Rect2(-2000, 0, 4000, 64))
	_dryer_column()
	var a := _spawn(1, Player.Hair.TWIN_TAILS, Vector2(-10, 0))
	var b := _spawn(2, Player.Hair.POMPADOUR, Vector2(10, 0))
	await _ticks(10)
	_hold(a, "skill", true)
	await _ticks(2)
	_hold(a, "jump", true)
	await _ticks(40)
	var y0 := a.global_position.y
	await _ticks(60)
	_hold(a, "jump", false)
	_hold(a, "skill", false)
	var rose := y0 - a.global_position.y   # one second of climbing
	_check(a.carrying == b and rose > 0.8 * 160.0 and rose < 1.2 * 160.0, "dryer: carrying a friend she still rises, slower (%.0f px/s, solo 300)" % rose)


## Combo "Hair-copter": pompadour stands on the gliding twin-tails' head and rides up.
func _hair_copter_lifts_the_rider() -> void:
	_new_arena()
	_box(Rect2(-2000, 0, 4000, 64))
	_dryer_column()
	var a := _spawn(1, Player.Hair.TWIN_TAILS, Vector2(0, 0))
	var b := _spawn(2, Player.Hair.POMPADOUR, Vector2(0, -2 * Player.HALF_SIZE.y - 4))
	await _ticks(20)
	_check(a.has_rider(b), "hair-copter: pompadour stands on twin-tails' head")
	_hold(a, "jump", true)
	_hold(a, "skill", true)
	await _ticks(100)
	_hold(a, "jump", false)
	_check(b.global_position.y < -10 * TILE and a.has_rider(b), "hair-copter: the rider goes up with her (y=%.0f)" % b.global_position.y)
	_hold(a, "skill", false)


func _shower_soaks_and_dryer_dries() -> void:
	_new_arena()
	_box(Rect2(-2000, 0, 4000, 64))
	var shower := ShowerHead.new()
	shower.off_time = 0.0
	shower.position = Vector2(-2 * TILE, -10 * TILE)
	shower.size = Vector2(4 * TILE, 10 * TILE)
	_arena.add_child(shower)
	var a := _spawn(1, Player.Hair.TWIN_TAILS, Vector2(0, 0))
	await _ticks(10)
	_check(a.is_wet(), "shower: standing under it soaks you")
	a.global_position = Vector2(20 * TILE, -8 * TILE)
	_hold(a, "skill", true)
	await _ticks(20)
	_check(not a.ability.is_gliding() and a.velocity.y > 200.0, "shower: wet twin-tails can't glide")
	_hold(a, "skill", false)
	await _wait(func(): return a.is_on_floor(), 120)
	var dryer := HairDryer.new()
	dryer.position = a.global_position - Vector2(TILE, 2 * TILE)
	dryer.size = Vector2(2 * TILE, 3 * TILE)
	_arena.add_child(dryer)
	await _ticks(5)
	_check(not a.is_wet(), "dryer: drying off is instant")


## Playtest 5: every air dash zeroed the fall, so chaining them let pompadour hover over
## any gap on her own (no carry needed). Now one dash per jump; landing recharges it.
func _one_air_dash_per_jump() -> void:
	_new_arena()
	_box(Rect2(-2000, 0, 4000, 64))
	# A long fall, so the second try is well inside the same flight.
	var b := _spawn(2, Player.Hair.POMPADOUR, Vector2(0, -40 * TILE))
	await _ticks(3)
	await _tap(b, "skill")
	_check(b.ability.is_driving(), "air dash: the first dash in the air works")
	await _ticks(30)   # past the 0.4 s cooldown
	_check(not b.is_on_floor(), "air dash: (still airborne for the second try)")
	await _tap(b, "skill")
	_check(not b.ability.is_driving(), "air dash: a second dash in the same flight does nothing")
	await _wait(func(): return b.is_on_floor(), 240)
	await _ticks(30)
	await _tap(b, "skill")
	_check(b.ability.is_driving(), "air dash: landing recharges it (ground dash works)")
	await _ticks(30)
	_hold(b, "jump", true)
	await _ticks(6)
	await _tap(b, "skill")
	_check(b.ability.is_driving(), "air dash: the next jump gets its air dash back")
	_hold(b, "jump", false)
	await _wait(func(): return b.is_on_floor(), 120)


## Where a running shower pours over a dryer column, the shower wins: you stay wet (and
## can't glide) until it stops, then the warm air dries you at once.
func _running_shower_beats_the_dryer() -> void:
	_new_arena()
	_box(Rect2(-2000, 0, 4000, 64))
	_dryer_column()
	var shower := ShowerHead.new()
	shower.off_time = 0.0
	shower.position = Vector2(-2 * TILE, -12 * TILE)
	shower.size = Vector2(4 * TILE, 12 * TILE)
	_arena.add_child(shower)
	var a := _spawn(1, Player.Hair.TWIN_TAILS, Vector2(0, 0))
	await _ticks(10)
	_check(a.is_wet(), "shower over dryer: the running spray keeps her wet in the warm air")
	shower.queue_free()
	await _ticks(3)
	_check(not a.is_wet(), "shower over dryer: once it stops, the dryer dries her at once")


## Playtest 6: touching the flat iron restarted the room. Now it costs one heart and
## throws you off it; cold or warming it's harmless.
func _hot_iron_burns_a_heart_not_a_life() -> void:
	_new_arena()
	_box(Rect2(-2000, 0, 4000, 64))
	var iron: HotIron = load("res://scenes/props/hot_iron.tscn").instantiate()
	iron.size = Vector2(2 * TILE, 24)
	iron.position = Vector2(-TILE, -24)
	_arena.add_child(iron)
	var a := _spawn(1, Player.Hair.TWIN_TAILS, Vector2(0, 0))
	await _ticks(5)
	iron._t = 0.0
	await _ticks(5)
	_check(a.alive and a.hp == a.max_hp, "iron: cold, it's harmless")
	iron._t = iron.off_time - 0.2
	await _ticks(3)
	_check(iron._is_warning() and a.hp == a.max_hp, "iron: warming up (the '!'), still harmless")
	a.global_position = Vector2(0, -Player.HALF_SIZE.y)
	await _wait(func(): return iron.is_active(), 60)
	await _ticks(3)
	_check(a.alive and a.hp == a.max_hp - 1, "iron: red-hot, it costs one heart - not a restart (hp=%d)" % a.hp)
	await _ticks(40)
	_check(absf(a.global_position.x) > iron.size.x / 2.0 + Player.HALF_SIZE.x, "iron: the burn throws you clear of it")


func _wet_pompadour_bounces_off_gel() -> void:
	_new_arena()
	_box(Rect2(-2000, 0, 4000, 64))
	var wall := _gel(Rect2(4 * TILE, -5 * TILE, 2 * TILE, 5 * TILE), 0.0)
	var b := _spawn(2, Player.Hair.POMPADOUR, Vector2(2 * TILE, 0))
	await _ticks(10)
	b.soak(5.0)
	await _tap(b, "skill")
	await _ticks(20)
	_check(is_instance_valid(wall) and wall.is_solid(), "wet: a soggy pompadour bounces off the gel")
	b.dry()
	await _ticks(25)
	await _tap(b, "skill")
	await _ticks(20)
	_check(not is_instance_valid(wall) or not wall.is_solid(), "wet: dried off, the dash smashes it")


func _tonic_grows_hair_back() -> void:
	_new_arena()
	_box(Rect2(-2000, 0, 4000, 64))
	var a := _spawn(1, Player.Hair.TWIN_TAILS, Vector2(0, 0))
	await _ticks(5)
	var full := GrowthTonic.new()
	full.position = a.global_position
	_arena.add_child(full)
	await _ticks(5)
	_check(is_instance_valid(full), "tonic: a friend with full hair leaves it")
	full.free()
	a.take_hit(1)
	_check(a.hp == 2 and _arena.get_children().any(func(n): return n is Player.HairSnip), "tonic: a hit costs a heart and snips a puff of hair")
	var tonic := GrowthTonic.new()
	tonic.position = a.global_position
	_arena.add_child(tonic)
	await _ticks(5)
	_check(a.hp == 3 and not is_instance_valid(tonic), "tonic: drinking it grows one notch back")


# --- Arena helpers -------------------------------------------------------------

func _new_arena() -> void:
	if _arena:
		_arena.free()
	for action in InputMap.get_actions():
		Input.action_release(action)
	_arena = Node2D.new()
	root.add_child(_arena)


func _box(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = Layers.WORLD
	Player.add_rect_shape(body, rect.size, rect.get_center())
	_arena.add_child(body)


func _gel(rect: Rect2, regrow: float) -> BreakableWall:
	var wall: BreakableWall = WallScene.instantiate()
	wall.position = rect.position
	wall.size = rect.size
	wall.regrow_time = regrow
	_arena.add_child(wall)
	return wall


func _spawn(id: int, hair: int, feet: Vector2) -> Player:
	var p: Player = PlayerScene.instantiate()
	p.player_id = id
	p.hair = hair
	_arena.add_child(p)
	p.global_position = feet - Vector2(0, Player.HALF_SIZE.y)
	return p


func _scissor(at: Vector2, dir: Vector2, parried: bool) -> Scissor:
	var s := Scissor.new()
	s.direction = dir
	s.position = at
	_arena.add_child(s)
	if parried:
		s.deflect()
		s.direction = dir
		s.rotation = dir.angle()
	return s


func _hold(p: Player, action: String, on: bool) -> void:
	var name := "p%d_%s" % [p.player_id, action]
	if on:
		Input.action_press(name)
	else:
		Input.action_release(name)


func _tap(p: Player, action: String) -> void:
	_hold(p, action, true)
	await physics_frame
	_hold(p, action, false)
	await physics_frame


func _ticks(n: int) -> void:
	for i in n:
		await physics_frame


func _wait(cond: Callable, max_ticks: int) -> bool:
	for i in max_ticks:
		if cond.call():
			return true
		await physics_frame
	return cond.call()


func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("  ok   ", label)
	else:
		failed += 1
		print("  FAIL ", label)
