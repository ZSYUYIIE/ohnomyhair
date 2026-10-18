extends LevelBuilder
## Generates L3 "Wash & Blow-Dry": res://scenes/levels/level_03.tscn.
## New salon mechanics (docs/levels/level_03.md):
##   hair dryers - warm air lifts a gliding twin-tails, slower when she carries a friend
##                 (pompadour riding on her head goes up at full speed: "Hair-copter");
##   shampoo showers - soak you for a few seconds: wet twin-tails can't glide (so can't
##                 carry), wet pompadour can't smash gel; a hair dryer dries you at once.
## Room 1 teaches the dryer, room 2 the shower, room 3 tests both together.
## Measured reach (one air dash per jump): from 6 up, pompadour alone clears 13.0 tiles and
## a carry 15.7; from 12 up, 15.0 vs 23.4. The dye pools sit between those numbers.
## Rerunning OVERWRITES the scene (see LevelBuilder).
## Run: godot --headless --path . --script res://tools/build_level_03.gd


func _configure() -> void:
	level_name = "Level03"
	level_title = "LEVEL 3 - Wash & Blow-Dry"
	next_level = "res://scenes/levels/level_04.tscn"
	scene_path = "res://scenes/levels/level_03.tscn"
	tile_atlas = "res://assets/art/l3/tiles_l3.png"
	tileset_path = "res://assets/art/l3/salon_tileset.tres"


func _rooms() -> Array:
	return [_room_1(), _room_2(), _room_3()]


## Room 1: a dryer lifts P1 alone to a lever shelf (the gate opens for both).
## Then the exit ledge is 11 up: P1 grabs P2 and the big dryer lifts them both, slowly.
func _room_1() -> RoomBuilder:
	var rb := RoomBuilder.new(self, room_node("Room1", "1 - Blow-Dry Bar", Color("fbe9de"), "res://assets/art/l3/bg_l3_01_blow_dry.png"))
	rb.solid(0, 19, 38, 22)
	rb.spawn(1, 2, 19)
	rb.spawn(2, 4, 19)
	rb.dryer("SoloDryer", 6, 7, 2, 18)
	rb.solid(9, 9, 13, 10)        # lever shelf, 10 up: only the warm air gets you there
	var lever := rb.lever("GateLever", 12, 8)
	rb.solid(16, 1, 16, 12)       # wall above the gate
	var gate := rb.block("Gate", 16, 13, 1, 6, Vector2i(0, -5), lever)
	gate.color = Color("8e6e53")
	rb.dryer("BigDryer", 22, 5, 2, 18)
	rb.solid(26, 8, 38, 18)       # exit ledge, 11 up
	rb.exit(35, 5)
	rb.gate("Lever shelf 10 up", ["glide"])
	rb.gate("Gate lever", ["lever", "lasso_lever"])
	rb.gate("Exit ledge 11 up, both friends", ["hair_copter", "spring"])
	rb.hint("Warm air lifts a glider:
{tt}: jump + HOLD {tt.skill} in the dryer", Vector2(40, 330))
	rb.hint("It lifts you both too!
{tt}: grab {pomp}, then glide into the dryer
({pomp} riding on {tt}'s head goes up faster)", Vector2(520, 330))
	return rb


## Room 2: the shower lesson. A timed shower soaks the 9-up take-off counter: wet tails
## can't glide, so the carry over the 17-wide dye (too wide for pompadour alone) has to go
## between sprays. Soaked? Step down - hair dries by itself in a few seconds.
## Far side: a soggy pompadour bounces off gel. The dryer before the rinse shower dries
## you at once; cross between sprays and smash the gel.
func _room_2() -> RoomBuilder:
	var rb := RoomBuilder.new(self, room_node("Room2", "2 - Shampoo Station", Color("e2f1f4"), "res://assets/art/l3/bg_l3_02_shampoo.png"))
	rb.solid(0, 19, 3, 22)        # start floor
	rb.solid(4, 17, 5, 22)        # stairs up to the counter
	rb.solid(6, 15, 7, 22)
	rb.solid(8, 13, 9, 22)
	rb.solid(10, 10, 12, 22)      # take-off counter, 9 up
	rb.dye_pool("DyePool", 13, 20, 17, 2)
	rb.solid(13, 22, 29, 22)
	rb.solid(30, 19, 38, 22)      # landing
	rb.spawn(1, 1, 19)
	rb.spawn(2, 3, 19)
	rb.shower("TakeOffShower", 9, 1, 4, 9, 1.8, 1.6)
	rb.dryer("DryingDryer", 30, 15, 2, 18)
	rb.shower("RinseCurtain", 32, 1, 3, 18, 1.8, 1.6, 0.9)
	rb.gel_wall("GelWall", 35, 13, 2, 6)
	rb.exit(37, 16)
	rb.gate("17-wide dye pool from 9 up, both friends", ["carry"])
	rb.gate("Shower over the take-off counter", ["walk"])
	rb.gate("Gel wall behind a shower", ["dash_gel"])
	rb.hint("Wet tails can't glide - or carry!
Go between sprays.
Soaked? Step down, hair dries.", Vector2(450, 170))
	rb.hint("A soggy pompadour
bounces off gel.
Dry off in the dryer,
then cross between sprays", Vector2(900, 200))
	return rb


## Room 3: both mechanics, twice. Up: carry P2 up the dryer column through a timed
## shower that pours across it - soaked, you drop back into the warm air, which dries you
## (the spray wins while it pours), so wait under it for a gap. Down: from the 12-up ledge,
## carry P2 over an 18-wide dye pool (pompadour alone: 15) under a second timed shower;
## soaked mid-flight, you both fall in. Take off the moment it stops.
func _room_3() -> RoomBuilder:
	var rb := RoomBuilder.new(self, room_node("Room3", "3 - Rinse & Repeat", Color("f3e6f4"), "res://assets/art/l3/bg_l3_03_rinse.png"))
	rb.solid(0, 19, 8, 22)        # start floor, at the foot of the dryer
	rb.spawn(1, 2, 19)
	rb.spawn(2, 3, 19)
	rb.dryer("LiftDryer", 5, 3, 2, 18)
	rb.shower("ColumnShower", 4, 1, 4, 12, 3.0, 1.4)
	rb.solid(9, 7, 15, 22)        # upper ledge, 12 up
	rb.dye_pool("DyePool", 16, 20, 18, 2)
	rb.solid(16, 22, 33, 22)
	rb.shower("PoolShower", 23, 1, 3, 19, 2.6, 1.2, 1.0)
	rb.solid(34, 19, 38, 22)      # landing
	rb.exit(36, 16)
	rb.gate("Dryer column under a timed shower, both friends", ["hair_copter", "spring"])
	rb.gate("18-wide dye pool from 12 up under a shower, both friends", ["carry"])
	rb.hint("Carry {pomp} up the warm air.
Soaked? You drop back in -
wait for the spray to stop", Vector2(296, 262))
	rb.hint("Fly the moment
the spray stops!", Vector2(560, 300))
	return rb
