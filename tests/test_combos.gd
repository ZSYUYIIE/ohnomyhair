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
	await _volley_needs_a_parry_first()
	await _volley_reaches_over_the_head()
	await _sling_from_low_carry_does_not_clip()
	await _hit_stop_survives_its_caller()
	await _respawn_out_of_a_hazard_dies_once()
	await _golden_scissor_dazes_the_boss_longer()
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


# --- Volley -------------------------------------------------------------------

## An enemy scissor can't be volleyed; only one pompadour parried first.
func _volley_needs_a_parry_first() -> void:
	_new_arena()
	_box(Rect2(-2000, 0, 4000, 64))
	var a := _spawn(1, Player.Hair.TWIN_TAILS, Vector2(0, 0))
	await _ticks(10)
	var raw := _scissor(Vector2(40, -30), Vector2.LEFT, false)
	await _tap(a, "attack")
	_check(not raw.golden, "volley: an enemy scissor is not volleyed by the whip")
	await _ticks(30)
	var parried := _scissor(Vector2(-40, -30), Vector2.RIGHT, true)
	await _tap(a, "attack")
	await physics_frame
	_check(is_instance_valid(parried) and parried.golden and parried.direction == Vector2.UP, "volley: a parried scissor turns golden and flies straight up")


## Twin-tails crouching in a trench: enemy scissors pass over her head, and her whip
## still reaches the parried one on its way back.
func _volley_reaches_over_the_head() -> void:
	_new_arena()
	_box(Rect2(-2000, 0, 4000, 64))
	var a := _spawn(1, Player.Hair.TWIN_TAILS, Vector2(0, 0))
	var b := _spawn(2, Player.Hair.POMPADOUR, Vector2(-8 * TILE, -2 * TILE))
	_box(Rect2(-12 * TILE, -2 * TILE, 10 * TILE, 2 * TILE))   # pompadour's ledge: 2 tiles up
	await _ticks(10)
	# Body height of a player on the ledge is ~1.5 tiles above twin-tails' head.
	var line_y := b.global_position.y
	var s := _scissor(Vector2(10 * TILE, line_y), Vector2.LEFT, false)
	b.facing = 1.0
	b.visual.scale.x = 1.0
	await _wait(func(): return not is_instance_valid(s) or s.global_position.x - b.global_position.x < 36.0, 300)
	_check(a.hp == a.max_hp, "volley: the enemy scissor flew over twin-tails in the trench")
	await _tap(b, "attack")
	_check(is_instance_valid(s) and s.deflected, "volley: pompadour parries it back")
	await _wait(func(): return not is_instance_valid(s) or s.global_position.x > a.global_position.x - 30.0, 120)
	await _tap(a, "attack")
	await physics_frame
	_check(is_instance_valid(s) and s.golden, "volley: twin-tails whips it up from the trench")


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
	_check(boss.state == BarberBot.State.DAZED and boss._t > 5.0, "boss: a golden (volleyed) scissor dazes it for 6 s")


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
