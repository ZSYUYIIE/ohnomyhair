extends SceneTree
## Physical G-key interaction: reversible levers, empty/blocked input and full pull frames.
const PlayerScene := preload("res://scenes/player/player.tscn")
const LeverScene := preload("res://scenes/props/lever.tscn")
const BlockScene := preload("res://scenes/props/moving_block.tscn")
const PullFrames := preload("res://scenes/player/pull_frames.gd")
var passed := 0
var failed := 0
var arena: Node2D
var player: Player
var lever: Lever
var events: Array[bool] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = Layers.WORLD
	Player.add_rect_shape(floor_body, Vector2(1200, 32), Vector2(0, 16))
	arena.add_child(floor_body)
	player = PlayerScene.instantiate()
	player.position = Vector2(0, -22)
	arena.add_child(player)
	lever = LeverScene.instantiate()
	lever.position = Vector2(35, -16)
	lever.toggled.connect(func(on): events.append(on))
	arena.add_child(lever)
	var block: MovingBlock = BlockScene.instantiate()
	block.position = Vector2(200, -32)
	block.move_offset = Vector2(0, -64)
	block.duration = 0.06
	block.trigger = lever
	arena.add_child(block)
	await ticks(10)
	check(player.is_on_floor() and not lever.one_shot, "authored levers default to reversible toggles")
	await tap()
	await ticks(8)
	check(lever.is_on and events == [true], "first G pull turns the lever on once")
	check(block.position.is_equal_approx(Vector2(200, -96)), "the connected platform moves out")
	check(player.sprite.animation == &"pull", "an accepted pull plays its interaction animation")
	check(player.sprite.scale.is_equal_approx(Vector2.ONE * PullFrames.SCALE), "pull uses the wider source frames at the original character scale")
	await tap()
	await ticks(8)
	check(not lever.is_on and events == [true, false], "second G pull turns the lever back off")
	check(block.position.is_equal_approx(Vector2(200, -32)), "the connected platform returns home")
	Input.action_press("p1_skill")
	await ticks(10)
	check(lever.is_on and events == [true, false, true], "holding G does not repeatedly toggle the lever")
	Input.action_release("p1_skill")
	await ticks(35)
	lever.position.x = 300
	await ticks(5)
	await tap()
	check(player.ability.anim() == &"" and player.sprite.animation == &"idle", "grounded G with nothing in reach does not play a skill or pull pose")
	check(player.sprite.scale == Vector2.ONE and player.sprite.material == null, "ordinary animations restore their original render settings")
	check(player.shape.shape.size == Vector2(28, 44), "sprite framing never changes the player's collision box")
	Input.action_press("p1_skill")
	await ticks(20)
	check(not player.ability.is_gliding() and player.ability.anim() == &"", "holding G on empty ground stays idle")
	Input.action_release("p1_skill")
	lever.position.x = 35
	lever.one_shot = true
	await ticks(5)
	await tap()
	check(player.ability.anim() == &"" and lever.is_on, "a blocked one-shot interaction cannot start a fake pull")
	lever.one_shot = false
	lever.is_on = false
	var closer: Lever = LeverScene.instantiate()
	closer.position = Vector2(-20, -16)
	arena.add_child(closer)
	await ticks(5)
	await tap()
	check(closer.is_on and not lever.is_on, "only the nearest reachable lever is toggled")
	check(player.facing == -1.0, "the pull faces the lever being used")
	await ticks(35)
	closer.position.x = -300
	lever.position.x = 300
	player.velocity.y = -400
	await ticks(4)
	Input.action_press("p1_skill")
	await ticks(3)
	check(player.ability.is_gliding(), "G in open air still performs the real glide skill")
	Input.action_release("p1_skill")
	var spring: Lever = LeverScene.instantiate()
	spring.spring_time = 0.2
	spring.position.x = 450
	arena.add_child(spring)
	check(spring.interact(player), "timed levers still accept a pull")
	await ticks(6)
	check(spring.interact(player), "pulling a timed lever again rearms its timer")
	await ticks(7)
	check(spring.is_on, "the rearmed timed lever stays on until its new deadline")
	await ticks(8)
	check(not spring.is_on, "timed levers still spring back automatically")
	check(not _has_clipped_pull_frame(), "all six pull regions have clear borders around the full hair silhouette")
	check(PullFrames.get_frames().get_frame_texture(&"pull", 1).region.end.x > 362,
		"the extended tail beyond the old sprite-cell boundary is included")
	arena.queue_free()
	await ticks(3)
	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func _has_clipped_pull_frame() -> bool:
	var image: Image = PullFrames.SHEET.get_image()
	for texture_index in 6:
		var texture: AtlasTexture = PullFrames.get_frames().get_frame_texture(&"pull", texture_index)
		var r := Rect2i(texture.region)
		for x in range(r.position.x, r.end.x):
			if image.get_pixel(x, r.position.y).a > 0.5 or image.get_pixel(x, r.end.y - 1).a > 0.5: return true
		for y in range(r.position.y, r.end.y):
			if image.get_pixel(r.position.x, y).a > 0.5 or image.get_pixel(r.end.x - 1, y).a > 0.5: return true
	return false

func tap() -> void:
	Input.action_press("p1_skill")
	await ticks(2)
	Input.action_release("p1_skill")
	await ticks(2)

func ticks(n: int) -> void:
	for i in n: await physics_frame

func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("  ok   ", label)
	else:
		failed += 1
		print("  FAIL ", label)
