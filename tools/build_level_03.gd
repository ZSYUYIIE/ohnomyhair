extends LevelBuilder
## Generates L3 "The Barber": res://scenes/levels/level_03.tscn.
## Room 1 puts L1's carry and L2's parry under pressure together, room 2 swaps the
## friends' haircuts (Something's Off), room 3 is the barber-bot boss.
## Rerunning OVERWRITES the scene (see LevelBuilder).
## Run: godot --headless --path . --script res://tools/build_level_03.gd

var ChairScene := load("res://scenes/props/hair_swap_chair.tscn")


func _configure() -> void:
	level_name = "Level03"
	level_title = "LEVEL 3 - The Barber"
	scene_path = "res://scenes/levels/level_03.tscn"
	ending_text = "THE END\n\nThe barber offers to fix your hair.\nYou look at each other... and say no.\nBad hair. Good friends."


func _rooms() -> Array:
	return [_room_1(), _room_2(), _room_3()]


## Room 1: a turret fires along the take-off ledge and the carry's flight line.
## Parry first to jam it, or parry while being carried. A clipper bot guards the landing.
func _room_1() -> RoomBuilder:
	var rb := RoomBuilder.new(self, room_node("Room1", "1 - Closing Time", Color("efe3d0")))
	rb.solid(0, 19, 6, 22)      # start floor
	rb.solid(7, 17, 11, 22)     # take-off ledge (2 up)
	rb.solid(21, 19, 38, 22)    # landing (pool is 9 wide: carry from the ledge clears 11.4)
	rb.dye_pool("DyePool", 12, 20, 9, 2)
	rb.spawn(1, 2, 19)
	rb.spawn(2, 4, 19)
	# Row 16 is ledge-body / flight height; players on the low floors are under it.
	rb.turret("Turret", 38, 16, Vector2.LEFT, 3.0, 1.5)
	rb.clipper("ClipperBot", 29, 19, 4.0)
	rb.exit(36, 16)
	rb.hint("Closing time. The barber's robot wants to finish the job.", Vector2(40, 300))
	rb.hint("Scissors at ledge height!\nP2: parry them back (L) - even while carried", Vector2(200, 400))
	rb.hint("Clipper bot: whip (F) stuns, dash (K) smashes", Vector2(700, 470))
	return rb


## Room 2: the barber's chair sits in a tunnel everyone must pass. Afterwards the
## gel wall needs P1's new dash and the cliff needs P1 to launch P2.
func _room_2() -> RoomBuilder:
	var rb := RoomBuilder.new(self, room_node("Room2", "2 - The Chair", Color("f6dde4")))
	rb.solid(0, 19, 38, 22)     # floor
	rb.solid(15, 1, 24, 14)     # low ceiling: the chair tunnel is rows 15-18
	rb.solid(33, 13, 38, 22)    # cliff (6 up)
	rb.spawn(1, 2, 19)
	rb.spawn(2, 4, 19)
	var chair: Node2D = ChairScene.instantiate()
	chair.position = Vector2(16, 15) * TILE
	chair.size = Vector2(8, 4) * TILE
	rb.add(chair, "HairSwapChair")
	rb.gel_wall("GelWall", 27, 13, 2, 6)
	var lever := rb.lever("Lever", 35, 12)
	rb.block("RisingStep", 31, 19, 2, 3, Vector2i(0, -3), lever, true)
	rb.exit(36, 10)
	rb.hint("The barber's chair.\nTake a seat...?", Vector2(40, 330))
	# Revealed by the chair, so the swap isn't spoiled.
	var after := Node2D.new()
	after.visible = false
	rb.add(after, "AfterSwapHints")
	for line in [["P1 is the POMPADOUR now:\nG dash / launch,   F parry", Vector2(820, 180)],
			["P2 is the TWIN-TAILS now:\nK glide / grab / pull lever,   L whip", Vector2(820, 260)]]:
		var label := Label.new()
		label.text = line[0]
		label.position = line[1]
		label.add_theme_color_override("font_color", Color("b0306a"))
		label.add_theme_font_size_override("font_size", 20)
		after.add_child(label)
	rb.link(chair, "swapped", after, "show")
	return rb


## Room 3: the barber bot. Parry its scissors (or make it crash a charge) to daze it,
## then land on its head knob: launch from a friend's head, or glide from a ledge.
func _room_3() -> RoomBuilder:
	var rb := RoomBuilder.new(self, room_node("Room3", "3 - The Barber Bot", Color("e2d6d6")))
	rb.node.starts_with_swapped_hair = true
	rb.solid(0, 19, 38, 22)     # arena floor
	# Corner ledges only: a charge crashes the bot right under them, so you can drop
	# (down) or walk off onto its knob. The middle stays open for launches.
	rb.one_way(1, 4, 16)
	rb.one_way(1, 3, 12)
	rb.one_way(32, 35, 16)
	rb.one_way(33, 35, 12)
	rb.spawn(1, 12, 19)         # clear of the stairs, so nobody spawns under a platform
	rb.spawn(2, 14, 19)
	var boss := BarberBot.new()
	boss.position = Vector2(24 * TILE + TILE / 2, 19 * TILE)
	rb.add(boss, "BarberBot")
	var door := rb.door("BossDoor", 36, 1, 1, 18)
	rb.link(boss, "defeated", door, "open")
	rb.exit(37, 16)
	rb.hint("Parry its scissors back to daze it (P1: F),\nthen land on the glowing head knob!", Vector2(330, 60))
	rb.hint("Carry P2 over on P1's head and launch (G) - or drop from a corner ledge (hold down)", Vector2(330, 120))
	return rb
