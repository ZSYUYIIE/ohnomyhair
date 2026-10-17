extends LevelBuilder
## Generates L2 "Scissor Corridor": res://scenes/levels/level_02.tscn.
## Design and map: docs/levels/level_02.md (same 40x22 grid, now 32px tiles).
## Rerunning OVERWRITES the scene (see LevelBuilder).
## Run: godot --headless --path . --script res://tools/build_level_02.gd

## Terrain only ('#' solid, '=' one-way); entities are placed below by tile coords.
## Keep in sync with the map in docs/levels/level_02.md.
const MAP := [
	"########################################",
	"#......................................#",
	"#......................................#",
	"#......................................#",
	"#......................................#",
	"#......................................#",
	"#......................................#",
	"#................======................#",
	"#......................................#",
	"#......................................#",
	"#......................................#",
	"#......................................#",
	"#......................................#",
	"#......................................#",
	"#......................................#",
	"#................##################....#",
	"#................#.....................#",
	"#..............###.....................#",
	"#..............###.................====#",
	"#............#####.....................#",
	"#............#####.....................#",
	"########################################",
]
const LEVER_SPRING_TIME := 2.5


func _configure() -> void:
	level_name = "Level02"
	level_title = "LEVEL 2 - Scissor Corridor"
	next_level = "res://scenes/levels/level_03.tscn"
	scene_path = "res://scenes/levels/level_02.tscn"


func _rooms() -> Array:
	var rb := RoomBuilder.new(self, room_node("Room1", "Parry together", Color("e3dcef")))
	rb.ascii(MAP)
	rb.spawn(1, 2, 21)
	rb.spawn(2, 3, 21)
	rb.clipper("ClipperBot", 8, 21, 3.0)
	rb.turret("Turret", 38, 14, Vector2.LEFT)
	var plate := rb.deflector("Deflector", 28, 14)
	var lever := rb.lever("Lever", 21, 6, LEVER_SPRING_TIME)
	rb.link(lever, "toggled", plate, "set_raised")
	var door := rb.door("Door", 24, 16, 1, 5)
	var switch := rb.hit_switch("Switch", 28, 1)
	rb.link(switch, "activated", door, "open")
	# P2 must parry at least a tile left of the plate, or the parried scissor never passes through it.
	rb.stripes("ParryStripes", 17, 26, 15)
	rb.exit(19, 19, 4, 2)
	rb.hint("P1  A/D move   W jump   G glide + pull lever   F hair whip", Vector2(48, 48))
	rb.hint("P2  Arrows move   Up jump   K dash / launch   L parry", Vector2(48, 76))
	rb.hint("P1 stand on P2's head, P2 press K", Vector2(440, 300))
	rb.hint("P2 parry (L) on the yellow stripes", Vector2(552, 380))
	return [rb]
