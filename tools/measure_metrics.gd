extends SceneTree
## Measures the real movement numbers by simulating input, so level gaps can be
## sized against them. Prints everything in tiles (32px).
## Run: godot --headless --fixed-fps 60 --path . --script res://tools/measure_metrics.gd

const TILE := 32.0
const PlayerScene := preload("res://scenes/player/player.tscn")
const LEDGE_HEIGHT := 20 * TILE  # tall take-off ledge, so one flight gives reach at every drop
const EDGE_X := 0.0

var _arena: Node2D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var jump := await _flight(false, false)
	var glide := await _flight(true, false)
	var carry := await _flight(true, true)
	print("\n== Reach from a running take-off (tiles of gap you can clear) ==")
	print("                     same height   land 2 lower   land 6 lower")
	_print_reach("jump", jump)
	_print_reach("glide (P1 alone)", glide)
	_print_reach("carry (P1 + P2)", carry)
	print("jump apex height: %.2f tiles" % (jump.apex / TILE))
	print("carry: P2's feet hang %.2f tiles below P1's feet" % (carry.hang / TILE))
	print("launch: rider's feet peak %.2f tiles above the floor" % (await _launch() / TILE))
	print("dash: %.2f tiles" % (await _dash() / TILE))
	quit()


func _print_reach(label: String, f: Dictionary) -> void:
	print("%-20s %8.2f      %8.2f       %8.2f" % [label, f.reach[0] / TILE, f.reach[1] / TILE, f.reach[2] / TILE])


func _new_arena() -> void:
	if _arena:
		_arena.free()
	_arena = Node2D.new()
	root.add_child(_arena)
	# Ledge to the left of EDGE_X with its top at y=0, ground far below.
	_add_box(Rect2(-3000, 0, 3000 + EDGE_X, LEDGE_HEIGHT))
	_add_box(Rect2(-3000, LEDGE_HEIGHT, 20000, 64))


func _add_box(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.position = rect.get_center()
	body.add_child(shape)
	_arena.add_child(body)


func _spawn(id: int, hair: int, feet: Vector2) -> Player:
	var p: Player = PlayerScene.instantiate()
	p.player_id = id
	p.hair = hair
	_arena.add_child(p)
	p.global_position = feet - Vector2(0, Player.HALF_SIZE.y)
	return p


func _feet(p: Player) -> float:
	return p.global_position.y + Player.HALF_SIZE.y


func _ticks(n: int) -> void:
	for i in n:
		await physics_frame


## Run off the ledge edge at full speed, jumping at the lip. Returns how far
## past the edge the pair's front reaches before its lowest feet drop below
## 0, 2 and 6 tiles under the ledge top.
func _flight(hold_skill: bool, with_friend: bool) -> Dictionary:
	_new_arena()
	var a := _spawn(1, Player.Hair.TWIN_TAILS, Vector2(EDGE_X - 600, 0))
	var b: Player = null
	if with_friend:
		b = _spawn(2, Player.Hair.POMPADOUR, Vector2(EDGE_X - 570, 0))
	await _ticks(10)
	if hold_skill:
		Input.action_press("p1_skill")
	await _ticks(2)
	if with_friend and a.carrying != b:
		push_error("grab failed")
	Input.action_press("p1_right")
	var jumped := false
	var apex := 0.0
	var hang := 0.0
	var reach := [-1.0, -1.0, -1.0]
	var drops := [0.0, 2 * TILE, 6 * TILE]
	for i in 600:
		await physics_frame
		if not jumped and a.global_position.x >= EDGE_X + 10:
			Input.action_press("p1_jump")
			jumped = true
		if not jumped:
			continue
		var bottom := _feet(a)
		if b:
			bottom = maxf(bottom, _feet(b))
			hang = maxf(hang, _feet(b) - _feet(a))
		apex = maxf(apex, -_feet(a))
		var front := a.global_position.x + Player.HALF_SIZE.x - EDGE_X
		for k in 3:
			if reach[k] < 0.0 and bottom > drops[k] and a.velocity.y > 0.0:
				reach[k] = front
		if reach[2] >= 0.0:
			break
	for action in ["p1_skill", "p1_right", "p1_jump"]:
		Input.action_release(action)
	return {"reach": reach, "apex": apex, "hang": hang}


func _launch() -> float:
	_new_arena()
	var b := _spawn(2, Player.Hair.POMPADOUR, Vector2(-400, 0))
	var a := _spawn(1, Player.Hair.TWIN_TAILS, Vector2(-400, -2 * Player.HALF_SIZE.y - 2))
	await _ticks(20)
	Input.action_press("p2_skill")
	await physics_frame
	Input.action_release("p2_skill")
	var peak := 0.0
	for i in 120:
		await physics_frame
		peak = maxf(peak, -_feet(a))
	return peak


func _dash() -> float:
	_new_arena()
	var b := _spawn(2, Player.Hair.POMPADOUR, Vector2(-1500, 0))
	await _ticks(10)
	var x0 := b.global_position.x
	Input.action_press("p2_skill")
	await physics_frame
	Input.action_release("p2_skill")
	await _ticks(40)
	return b.global_position.x - x0
