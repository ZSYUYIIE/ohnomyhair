extends LevelBuilder
## Generates L2 "Return to Sender": res://scenes/levels/level_02.tscn.
## Teaches the Hair Catch combo (docs/design/refinement.md): pompadour parries a scissor
## (it turns blue), twin-tails waits in a trench under the scissor line holding skill, so
## her open pigtails catch the blue scissor; letting go tosses it straight up (golden)
## into a service bell on the ceiling. Only pompadour ever parries.
## Room 1 teaches parry, then the catch. Room 2 is the old corridor: two bells, one trench
## each, and a clipper bot that soaks up parried scissors between them.
## Rerunning OVERWRITES the scene (see LevelBuilder).
## Run: godot --headless --path . --script res://tools/build_level_02.gd

const PINK := Color("ff5fa2")

## Room 2 terrain ('#' solid, '=' one-way); entities are placed by tile coords below.
## Rows 15-16 at x=22-23 and x=30-31 are the catch trenches cut into the walkway.
const CORRIDOR := [
	"########################################",
	"#......................................#",
	"#......................................#",
	"#......................................#",
	"#......................................#",
	"#......................................#",
	"#......................................#",
	"#......................................#",
	"#......................................#",
	"#......................................#",
	"#......................................#",
	"#......................................#",
	"#......................................#",
	"#......................................#",
	"#......................................#",
	"#................#####..######..###....#",
	"#................#.....................#",
	"#..............###....##......##.......#",
	"#..............###.................====#",
	"#............#####.....................#",
	"#............#####.....................#",
	"########################################",
]


func _configure() -> void:
	level_name = "Level02"
	level_title = "LEVEL 2 - Return to Sender"
	next_level = "res://scenes/levels/level_03.tscn"
	scene_path = "res://scenes/levels/level_02.tscn"
	tile_atlas = "res://assets/art/l2/tiles_l2.png"
	tileset_path = "res://assets/art/l2/salon_tileset.tres"


func _rooms() -> Array:
	return [_room_1(), _room_2()]


## Room 1: a scissor dispenser fires along body height. Parrying alone just jams it;
## the bell over the trench only rings for a caught-and-tossed scissor. Shelves lead up to the door.
func _room_1() -> RoomBuilder:
	var rb := RoomBuilder.new(self, room_node("Room1", "1 - Return to Sender", Color("e3dcef"), "res://assets/art/l2/bg_l2_01_reception.png"))
	rb.solid(0, 19, 19, 22)
	rb.solid(22, 19, 38, 22)
	# Trench at x=20-21, 2 deep: scissors fly over a player in it. Two tiles wide: a
	# one-tile hole left a 28 px body 4 px to fall in (docs/difficulty/report.md).
	rb.solid(20, 21, 21, 22)
	rb.one_way(23, 27, 16)      # shelves up to the exit (3 tiles apart)
	rb.one_way(26, 29, 13)
	rb.one_way(28, 31, 10)
	rb.solid(32, 10, 38, 12)    # exit counter, above the dispenser
	rb.solid(32, 1, 32, 6)      # wall above the staff door: no jumping over it
	rb.spawn(1, 3, 19)
	rb.spawn(2, 5, 19)
	rb.turret("Dispenser", 38, 18, Vector2.LEFT, 2.5, 2.0)
	var bell := rb.hit_switch("Bell", 20, 2, 16.0)
	var door := rb.door("StaffDoor", 32, 7, 1, 3)
	rb.link(bell, "activated", door, "open")
	rb.stripes("ParryStripes", 8, 18, 19)
	rb.stripes("CatchMark", 20, 21, 21, PINK)
	rb.gate("Dispenser on the body line", ["parry"])
	rb.gate("Ceiling bell", ["catch_toss"])
	rb.exit(35, 7)
	rb.hint("{pomp}: parry scissors back with  {pomp.attack}", Vector2(48, 400))
	rb.hint("{tt}: wait in the trench and HOLD {tt.skill}\nto catch the BLUE scissor - let go to toss it up", Vector2(420, 300))
	return rb


## Room 2: two bells, one trench each; the door needs both. The clipper bot patrols
## between the trenches and eats parried scissors meant for the far one.
func _room_2() -> RoomBuilder:
	var rb := RoomBuilder.new(self, room_node("Room2", "2 - Scissor Corridor", Color("dfe7f2"), "res://assets/art/l2/bg_l2_02_corridor.png"))
	rb.ascii(CORRIDOR)
	rb.spawn(1, 2, 21)
	rb.spawn(2, 3, 21)
	rb.clipper("ClipperBot", 8, 21, 3.0)
	rb.clipper("CorridorBot", 26, 15, 1.5)
	rb.turret("Dispenser", 38, 14, Vector2.LEFT)
	var door := rb.door("StaffDoor", 24, 16, 1, 5, 2)
	for col in [22, 30]:
		var bell := rb.hit_switch("Bell%d" % col, col, 1, 16.0)
		rb.link(bell, "activated", door, "open")
		rb.stripes("CatchMark%d" % col, col, col + 1, 17, PINK)
	rb.stripes("ParryStripes", 17, 21, 15)
	rb.exit(19, 18)
	rb.hint("Two bells. The door needs both.", Vector2(440, 300))
	rb.gate("Two ceiling bells", ["catch_toss"])
	rb.gate("Clipper bots", ["whip", "parry", "jump"])
	return rb
