extends LevelBuilder
## Generates chapter 4 "The Assistant" at its stable legacy path level_06.tscn.
## A rising curve:
##   1 Closing Time - warm-up recap: carry + parry under fire, a hot iron, a clipper bot;
##   2 The Chair    - the twist: the haircuts swap (Something's Off);
##   3 Rush Hour    - the robots arrive in three waves, each adding a threat; then a
##                    breather (hazards off, growth tonics);
##   4 The Runaway Assistant - the boss, in three phases (backup robots, then furious).
## Design notes: docs/levels/level_06.md.
## Rerunning OVERWRITES the scene (see LevelBuilder).
## Run: godot --headless --path . --script res://tools/build_level_06.gd

var ChairScene := load("res://scenes/props/hair_swap_chair.tscn")


func _configure() -> void:
	level_name = "Level06"
	level_title = "LEVEL 4 - The Assistant"
	scene_path = "res://scenes/levels/level_06.tscn"
	tile_atlas = "res://assets/art/l4/tiles_poster.svg"
	tileset_path = "res://assets/art/l4/salon_tileset.tres"
	ending_text = "THE END\n\nThe assistant powers down. The back door clicks open.\nYou take your friend's hand and run.\nBad hair. Good friends."


func _rooms() -> Array:
	return [_room_1(), _room_2(), _room_3(), _room_4()]


## Room 1: a turret fires along the take-off ledge and the carry's flight line.
## Parry first to jam it, or parry while being carried. A clipper bot guards the landing.
func _room_1() -> RoomBuilder:
	var rb := RoomBuilder.new(self, room_node("Room1", "1 - Closing Time", Color("efe3d0"), "res://assets/art/l4/bg_l4_01_closing.png"))
	rb.solid(0, 19, 6, 22)      # start floor
	rb.solid(7, 17, 11, 22)     # take-off ledge (2 up)
	rb.solid(21, 19, 38, 22)    # landing (pool is 9 wide: carry from the ledge clears 11.4)
	rb.dye_pool("DyePool", 12, 20, 9, 2)
	rb.spawn(1, 1, 19)          # two tiles clear of the flat iron, even after a restart
	rb.spawn(2, 2, 19)
	# Row 16 is ledge-body / flight height; players on the low floors are under it.
	rb.turret("Turret", 38, 16, Vector2.LEFT, 3.0, 1.5)
	rb.clipper("ClipperBot", 31, 19, 3.0)  # clear of the carry's landing (x=21-24)
	# A flat iron on the start floor, below the scissor line (a knockback can't throw
	# anyone onto it): time the walk between heats.
	rb.hot_iron("FlatIron", 5, 19, 2, 0.8)
	rb.exit(36, 16)
	rb.hint("Closing time. The barber's robot wants to finish the job.", Vector2(40, 300))
	rb.gate("9-wide dye pool, both friends", ["carry"], {"gap": 9, "drop": 2})
	rb.gate("Turret on the flight line", ["parry"])
	rb.gate("Clipper bot on the landing", ["whip", "parry", "jump"])
	rb.gate("Flat iron", ["walk"])
	rb.hint("{pomp} can parry ({pomp.attack}) while hanging from {tt}'s hair", Vector2(200, 420))
	return rb


## Room 2: the barber's chair sits in a tunnel everyone must pass, and swaps the haircuts.
## Then every combo runs with the roles reversed: P1 (now pompadour) dashes the gel and
## parries, P2 (now twin-tails) catches and tosses from the trench to ring the bell, P1 launches P2
## up the cliff, P2 pulls the lever so the step rises for P1.
func _room_2() -> RoomBuilder:
	var rb := RoomBuilder.new(self, room_node("Room2", "2 - The Chair", Color("f6dde4"), "res://assets/art/l4/bg_l4_02_chair.png"))
	rb.solid(0, 19, 26, 22)     # floor...
	rb.solid(29, 19, 38, 22)
	rb.solid(27, 21, 28, 22)    # ...with a catch trench at x=27-28
	rb.solid(15, 1, 22, 14)     # low ceiling: the chair tunnel is rows 15-18
	rb.solid(33, 13, 38, 22)    # cliff (6 up)
	rb.solid(34, 1, 34, 9)      # wall above the staff door
	rb.spawn(1, 2, 19)
	rb.spawn(2, 4, 19)
	var chair: Node2D = ChairScene.instantiate()
	chair.position = Vector2(15, 15) * TILE
	chair.size = Vector2(8, 4) * TILE
	rb.add(chair, "HairSwapChair")
	# Shields the room from the dispenser until P1 (pompadour after the swap) dashes it.
	rb.gel_wall("GelWall", 23, 13, 2, 6)
	rb.turret("Dispenser", 30, 18, Vector2.LEFT, 2.5, 1.0)  # fires left only: the launch spot behind it is safe
	var bell := rb.hit_switch("Bell", 27, 2, 16.0)
	var door := rb.door("StaffDoor", 34, 10, 1, 3)
	rb.link(bell, "activated", door, "open")
	rb.stripes("ParryStripes", 25, 26, 19)
	rb.stripes("CatchMark", 27, 28, 21, Color("ff5fa2"))
	var lever := rb.lever("ChairLever", 33, 12)
	rb.block("RisingStep", 31, 19, 2, 3, Vector2i(0, -3), lever, true)
	rb.exit(36, 10)
	rb.hint("The barber's chair.\nTake a seat...?", Vector2(40, 330))
	# Revealed by the chair, so the swap isn't spoiled.
	var after := Node2D.new()
	after.visible = false
	rb.add(after, "AfterSwapHints")
	for line in [["{pomp} is the POMPADOUR now:  {pomp.skill} dash / launch,  {pomp.attack} parry", Vector2(760, 60)],
			["{tt} is the TWIN-TAILS now:  {tt.skill} glide / grab / lever,  {tt.attack} whip", Vector2(760, 92)]]:
		var label := HairHint.new()
		label.template = line[0]
		label.text = HairHint.resolve(line[0], {Player.Hair.POMPADOUR: 1, Player.Hair.TWIN_TAILS: 2})
		label.position = line[1]
		label.add_theme_color_override("font_color", Color("b0306a"))
		label.add_theme_font_size_override("font_size", 18)
		after.add_child(label)
	rb.link(chair, "swapped", after, "show")
	rb.gate("Barber's chair tunnel (swaps roles)", ["walk"])
	rb.gate("Gel wall shielding the room", ["dash_gel"])
	rb.gate("Ceiling bell", ["catch_toss"])
	rb.gate("6-up cliff", ["launch"], {"rise": 6})
	rb.gate("Step lever", ["lever"])
	return rb


## Room 3: Rush Hour. The door to the workshop stays shut while the barber's robots
## arrive in waves through the ceiling vents, each wave adding a threat:
##   1 - two clipper bots (P1, now pompadour, dashes them apart; P2's whip stuns them);
##   2 - three bots and the scissor dispenser wakes up: parry its scissors into the bots,
##       or hide behind the counter / up on a shelf;
##   3 - a hot floor: the flat irons in the middle lanes heat up, and a bot drops on
##       each flank - cross the irons between heats to reach them.
## Wave robots break in one dash; a growth tonic appears on the counter after waves 1 and 2
## (a breather to recover hair). Then everything switches off, two more tonics appear
## and the door opens.
func _room_3() -> RoomBuilder:
	var rb := RoomBuilder.new(self, room_node("Room3", "3 - Rush Hour", Color("ead8d2"), "res://assets/art/l4/bg_l4_rush.png"))
	rb.styles([Player.Hair.POMPADOUR, Player.Hair.TWIN_TAILS], [Player.Hair.POMPADOUR, Player.Hair.TWIN_TAILS])  # after the swap; the chair only swaps roles
	rb.solid(0, 19, 38, 22)     # floor
	rb.solid(18, 17, 20, 18)    # counter: cover from the dispenser's scissors
	rb.one_way(6, 9, 16)        # shelves above the scissor line (3 up: a plain jump)
	rb.one_way(28, 31, 16)
	rb.solid(36, 1, 36, 12)     # wall above the door
	rb.spawn(1, 2, 19)          # clear of the shelves
	rb.spawn(2, 4, 19)
	rb.turret("Dispenser", 35, 18, Vector2.LEFT, 2.6, 1.2)
	rb.hot_iron("IronLeft", 11, 19, 2, 0.0)
	rb.hot_iron("IronRight", 25, 19, 2, 1.3)
	var door := rb.door("ArenaDoor", 36, 13, 1, 6)
	var arena := WaveArena.new()
	var waves: Array[Dictionary] = [
		{"drops": [14, 24], "tonic": 19},
		{"drops": [8, 24, 30], "wake": ["Dispenser"], "tonic": 19},
		{"drops": [4, 34], "wake": ["IronLeft", "IronRight"]},  # on the floor, clear of the shelves and the irons
	]
	arena.waves = waves
	arena.vent_row = 0
	arena.tonic_cols = PackedInt32Array([18, 20])
	arena.tonic_row = 16        # on top of the counter: the supply table
	rb.add(arena, "Waves")
	rb.link(arena, "cleared", door, "open")
	rb.exit(37, 16)
	rb.gate("Three waves of clipper bots", ["dash_gel", "parry", "whip"])
	rb.gate("Dispenser (wave 2)", ["parry"])
	rb.gate("Hot irons (wave 3)", ["walk"])
	rb.hint("Robots incoming!  {pomp} dash ({pomp.skill}) breaks them,  {tt} whip ({tt.attack}) stuns them", Vector2(130, 250))
	rb.hint("Parry ({pomp.attack}) the scissors back into the robots", Vector2(700, 330))
	return rb


## Room 4: the barber bot. Parry its scissors (or make it crash a charge) to daze it,
## then land on its head knob: launch from a friend's head, or glide from a ledge.
## Phase 2 calls backup robots through the corner vents; they power down when it falls.
func _room_4() -> RoomBuilder:
	var rb := RoomBuilder.new(self, room_node("Room4", "4 - The Runaway Assistant", Color("e2d6d6"), "res://assets/art/l4/bg_l4_03_workshop.png"))
	# The escape follows the same two friends. Restyles swap their familiar roles.
	rb.styles([Player.Hair.TWIN_TAILS, Player.Hair.POMPADOUR],
			[Player.Hair.POMPADOUR, Player.Hair.TWIN_TAILS])
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
	var backup := WaveArena.new()
	var waves: Array[Dictionary] = [{"drops": [3, 34]}]
	backup.waves = waves
	backup.auto_start = false
	backup.vent_row = 0
	backup.patrol_tiles = 2.0
	rb.add(backup, "Backup")
	rb.link(boss, "backup_called", backup, "start_next")
	rb.link(boss, "defeated", backup, "scrap_all")
	rb.exit(37, 16)
	rb.gate("Daze the assistant", ["crash", "parry"])
	rb.gate("Corner ledge 7 up, above the knob", ["launch"], {"rise": 7})
	rb.gate("Backup robots (phase 2)", ["dash_gel", "parry", "whip", "jump"])
	rb.hint("Daze it (parry its scissors, or make it crash a charge into a wall),\nthen land on its glowing head from a high corner ledge.", Vector2(300, 230))
	rb.hint("Its scissors SWAP YOUR TWO HAIRCUTS.\nWatch your skills. Protect your friend.", Vector2(56, 270))
	return rb
