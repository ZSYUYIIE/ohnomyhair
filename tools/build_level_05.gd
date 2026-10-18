extends LevelBuilder
## Generates L5 "Extensions": res://scenes/levels/level_05.tscn.
## P2's pompadour got extensions: the pair is Twin-Tails (P1) + Long Straight (P2).
## Long Straight hooks gold rings and lowers a hair rope; twin-tails still glides, carries
## and rides warm air (docs/design/roster_and_chapters.md, docs/levels/level_05.md).
## Room 1 teaches the ring, the rope and the lasso, room 2 mixes them with L3's dryer and
## L1's carry, room 3 is the exam. Rerunning OVERWRITES the scene (see LevelBuilder).
## Run: godot --headless --path . --script res://tools/build_level_05.gd


func _configure() -> void:
	level_name = "Level05"
	level_title = "LEVEL 5 - Extensions"
	next_level = "res://scenes/levels/level_06.tscn"
	scene_path = "res://scenes/levels/level_05.tscn"
	tile_atlas = "res://assets/art/l3/tiles_l3.png"
	tileset_path = "res://assets/art/l3/extensions_tileset.tres"
	pair = [Player.Hair.TWIN_TAILS, Player.Hair.LONG_STRAIGHT]


func _rooms() -> Array:
	return [_room_1(), _room_2(), _room_3()]


## Room 1: the bar is 9 up. Long Straight jumps and hooks the ring over its overhang;
## twin-tails can't gain height here, so Long Straight lowers a rope from the edge and
## twin-tails climbs. The exit gate's lever sits 4 up on the wall: too high to jump,
## close enough to lasso.
func _room_1() -> RoomBuilder:
	var rb := RoomBuilder.new(self, room_node("Room1", "1 - Extension Bar", Color("f3e6f4"), "res://assets/art/l3/bg_l3_03_rinse.png"))
	rb.solid(0, 19, 38, 22)
	rb.solid(22, 10, 38, 18)    # the bar, 9 up
	rb.one_way(19, 21, 10)      # its counter overhangs the floor: hook up through it
	rb.spawn(1, 3, 19)
	rb.spawn(2, 5, 19)
	rb.ring("GoldRing", Vector2(660, 262))
	# Wall-mounted, 4 above the bar top: no ledge under it, so nothing blocks a lasso.
	var lever := rb.lever("GateLever", 30, 5)
	var gate := rb.block("Gate", 33, 6, 1, 4, Vector2i(0, -4), lever)
	gate.color = Color("8e6e53")
	rb.exit(35, 7)
	rb.gate("Gold ring to the bar", ["hook"])
	rb.gate("Friend up the bar", ["rope"])
	rb.gate("Lever high on the wall", ["lasso_lever"])
	rb.hint("{long}: jump, then HOLD {long.skill} to hook the gold ring", Vector2(48, 330))
	rb.hint("{tt} can't get up there...\n{long}: at the edge, face out and HOLD {long.skill}:\nyour hair is a rope. {tt}: HOLD jump to climb.", Vector2(300, 120))
	rb.hint("Out of reach?\n{long}: lasso it ({long.attack})", Vector2(760, 90))
	return rb


## Room 2: the tower is 13 up. A dryer lifts a glider, and Long Straight rides up on
## twin-tails' head (the L3 Hair-copter, with a new friend). From up there twin-tails
## carries Long Straight over 21 tiles of dye (carry reaches ~25 from 13 up, ~20 from 9).
## A clipper bot patrols the landing: Long Straight can lasso it while hanging.
func _room_2() -> RoomBuilder:
	var rb := RoomBuilder.new(self, room_node("Room2", "2 - The Up-Do", Color("e2f1f4"), "res://assets/art/l3/bg_l3_02_shampoo.png"))
	rb.solid(0, 19, 5, 22)      # start floor
	rb.solid(6, 6, 11, 22)      # the tower, 13 up
	rb.dye_pool("DyePool", 12, 20, 21, 2)
	rb.solid(12, 22, 32, 22)
	rb.solid(33, 19, 38, 22)    # landing
	rb.spawn(1, 1, 19)
	rb.spawn(2, 5, 19)
	rb.dryer("Dryer", 3, 2, 2, 18)
	rb.clipper("ClipperBot", 36, 19, 2.0)
	rb.exit(36, 16)
	rb.gate("Tower 13 up, both friends", ["hair_copter", "spring"])
	rb.gate("21-wide dye pool from 13 up, both friends", ["carry"])
	rb.gate("Clipper bot on the landing", ["whip", "lasso_stun", "parry", "jump"])
	rb.hint("Too heavy to carry up?\nWarm air lifts a glider...\nand whatever stands on one.", Vector2(40, 270))
	rb.hint("{tt}: grab {long} at the edge and fly!\n{long} can lasso ({long.attack}) while hanging.", Vector2(420, 120))
	return rb


## Room 3: the exam. Hook the ring, lower the rope; the take-off end of the ledge is under
## a timed shower (wet tails can't fly: leave between sprays, or dry off). Then carry across
## 18 tiles of dye from 9 up, past a clipper bot, and lasso the gate lever.
func _room_3() -> RoomBuilder:
	var rb := RoomBuilder.new(self, room_node("Room3", "3 - Tangles", Color("e3dcef"), "res://assets/art/l1/bg_l1_02_washing_basin.png"))
	rb.solid(0, 19, 10, 22)     # start floor
	rb.one_way(6, 10, 10)       # ledge, 9 up
	rb.dye_pool("DyePool", 11, 20, 18, 2)
	rb.solid(11, 22, 28, 22)
	rb.solid(29, 19, 38, 22)    # landing
	rb.solid(34, 1, 34, 14)     # wall over the gate
	rb.spawn(1, 2, 19)
	rb.spawn(2, 4, 19)
	rb.ring("GoldRing", Vector2(276, 250))
	rb.dryer("Dryer", 1, 13, 2, 18)
	rb.shower("LedgeShower", 8, 1, 3, 9, 3.2, 1.2)  # the take-off end only: climb dry, leave between sprays
	rb.clipper("ClipperBot", 32, 19, 2.0)
	var lever := rb.lever("GateLever", 31, 13)  # wall-mounted, 5 up
	var gate := rb.block("Gate", 34, 15, 1, 4, Vector2i(0, -4), lever)
	gate.color = Color("8e6e53")
	rb.exit(36, 16)
	rb.gate("Gold ring to the ledge", ["hook"])
	rb.gate("Friend up the ledge", ["rope"])
	rb.gate("Shower over the take-off", ["walk"])
	rb.gate("18-wide dye pool from 9 up, both friends", ["carry"])
	rb.gate("Clipper bot on the landing", ["whip", "lasso_stun", "parry", "jump"])
	rb.gate("Gate lever 5 up", ["lasso_lever"])
	rb.hint("Wet tails can't fly.\nTake off between sprays.", Vector2(40, 140))
	rb.hint("{long}: lasso the lever ({long.attack})", Vector2(830, 330))
	return rb
