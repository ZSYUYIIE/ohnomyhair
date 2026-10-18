extends LevelBuilder
## A separate three-room expansion, available without changing campaign unlocks.
const Anchor := preload("res://scenes/props/hair_anchor.gd")

func _configure() -> void:
	level_name = "StyleLab"
	level_title = "STYLE LAB - Four Haircuts"
	scene_path = "res://scenes/levels/style_lab.tscn"
	ending_text = "STYLE LAB CLEAR!\nFour haircuts. Better together."
	tile_atlas = "res://assets/art/l1/tiles_salon.png"
	tileset_path = "res://assets/art/lab/salon_tileset.tres"

func _rooms() -> Array:
	return [_spring_room(), _rope_room(), _boss_room()]

func _spring_room() -> RoomBuilder:
	var rb := RoomBuilder.new(self, room_node("Room1", "1 - The Bounce Studio", Color("f6e7ec"), "res://assets/art/l1/bg_l1_01_mirror.png"))
	rb.styles([Player.Hair.AFRO, Player.Hair.POMPADOUR], [Player.Hair.AFRO, Player.Hair.POMPADOUR])
	rb.gate("Reinforced gel curtain", ["cannonball"])
	rb.gate("Shampoo shower", ["walk"])
	rb.solid(0, 19, 38, 22)
	rb.spawn(1, 3, 19)
	rb.spawn(2, 5, 19)
	var gel := rb.gel_wall("ReinforcedGel", 23, 1, 2, 18)
	gel.requires_cannonball = true
	rb.shower("Shampoo", 12, 1, 2, 18, 4.0, 1.0)
	rb.dryer("Dryer", 15, 13, 2, 18)
	rb.exit(36, 16)
	rb.hint("{afro} (Afro): hold {afro.skill} to charge; release to bounce a rider.\n{pomp}: jump on the Afro's head and hold {pomp.skill} as {afro} releases {afro.skill}.", Vector2(48, 220))
	rb.hint("CANNONBALL!\nOnly the co-op drill breaks orange gel.", Vector2(780, 250))
	rb.hint("Wet Afro hair collapses.\nDry off before charging.", Vector2(420, 400))
	return rb

func _rope_room() -> RoomBuilder:
	var rb := RoomBuilder.new(self, room_node("Room2", "2 - Rapunzel Crossing", Color("e9e0f6"), "res://assets/art/l1/bg_l1_03_gel_curtain.png"))
	rb.styles([Player.Hair.LONG_STRAIGHT, Player.Hair.TWIN_TAILS], [Player.Hair.LONG_STRAIGHT, Player.Hair.TWIN_TAILS])
	rb.gate("Gold ring to the high shelf", ["hook"])
	rb.gate("17-wide dye pool", ["rope_glide"])
	rb.gate("Bridge lever", ["lever", "lasso_lever"])
	rb.solid(0, 19, 9, 22)
	rb.solid(27, 19, 38, 22)
	rb.one_way(7, 10, 10)
	rb.dye_pool("DyePool", 10, 21, 17, 1)
	rb.spawn(1, 3, 19)
	rb.spawn(2, 5, 19)
	var ring := Anchor.new()
	ring.position = Vector2(328, 285)
	rb.add(ring, "GoldRing")
	var lever := rb.lever("BridgeLever", 31, 18)
	rb.block("Bridge", 10, 2, 17, 1, Vector2i(0, 17), lever)
	rb.exit(36, 16)
	rb.hint("{long} (Long Straight): jump, then hold {long.skill} to hook the gold ring.\nOn the ledge, face right and hold {long.skill} to lower a rope.", Vector2(48, 100))
	rb.hint("{tt}: hold jump beside the rope to climb.\nMove right to release; hold {tt.skill} to glide to the far side.", Vector2(400, 255))
	rb.hint("{tt}: {tt.skill} pulls the lever.\nThe bridge lets {long} cross too.", Vector2(890, 385))
	return rb

func _boss_room() -> RoomBuilder:
	var rb := RoomBuilder.new(self, room_node("Room3", "3 - Tony's Makeover", Color("e2d6d6"), "res://assets/art/l4/bg_l4_03_workshop.png"))
	rb.styles([Player.Hair.TWIN_TAILS, Player.Hair.POMPADOUR, Player.Hair.AFRO, Player.Hair.LONG_STRAIGHT],
			[Player.Hair.AFRO, Player.Hair.POMPADOUR])
	rb.gate("Daze Tony", ["crash", "parry", "catch_return", "cannonball"])
	rb.gate("Corner ledge 7 up, above the knob", ["launch", "spring", "hook"])
	rb.solid(0, 19, 38, 22)
	rb.one_way(1, 4, 16)
	rb.one_way(1, 3, 12)
	rb.one_way(32, 35, 16)
	rb.one_way(33, 35, 12)
	rb.spawn(1, 3, 19)
	rb.spawn(2, 5, 19)
	var boss := BarberBot.new()
	boss.position = Vector2(800, 608)
	rb.add(boss, "BarberBot")
	var door := rb.door("BossDoor", 36, 1, 1, 18)
	rb.link(boss, "defeated", door, "open")
	rb.exit(37, 16)
	rb.hint("Tony's scissors FORCE A NEW HAIRCUT when they hurt you.\nParry, return a caught scissor, or cannonball to daze him. Then stomp!", Vector2(240, 60))
	rb.hint("A style chair saves your chosen pair.\nRegroup and adapt!", Vector2(56, 240))
	return rb
