extends LevelBuilder
## Generates L3 "Wash & Blow-Dry": res://scenes/levels/level_03.tscn.
## New salon mechanics (docs/levels/level_03.md):
##   hair dryers - warm air lifts a gliding twin-tails; carrying a friend she only hovers,
##                 so pompadour rides on her head instead (combo "Hair-copter");
##   shampoo showers - soak you: wet twin-tails can't glide, wet pompadour can't smash gel;
##                 a hair dryer dries you instantly;
##   growth tonic - grows one notch of hair (1 HP) back.
## Room 1 teaches the dryer and the Hair-copter, room 2 the shower, room 3 tests it all.
## Rerunning OVERWRITES the scene (see LevelBuilder).
## Run: godot --headless --path . --script res://tools/build_level_03.gd


func _configure() -> void:
	level_name = "Level03"
	level_title = "LEVEL 3 - Wash & Blow-Dry"
	next_level = "res://scenes/levels/level_04.tscn"
	scene_path = "res://scenes/levels/level_03.tscn"


func _rooms() -> Array:
	return [_room_1(), _room_2(), _room_3()]


## Room 1: a dryer lifts P1 alone to a lever shelf (the gate opens for both).
## Then the exit ledge is 11 tiles up: carrying P2 in the warm air only hovers, so P2
## stands on P1's head and rides up (Hair-copter), then hops onto the ledge.
func _room_1() -> RoomBuilder:
	var rb := RoomBuilder.new(self, room_node("Room1", "1 - Blow-Dry Bar", Color("fbe9de")))
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
	rb.hint("Warm air lifts a glider:\nP1 jump + HOLD G in the dryer", Vector2(40, 330))
	rb.hint("Too heavy to carry up!\nP2: stand on P1's head and ride", Vector2(560, 330))
	return rb


## Room 2: a timed shower soaks the take-off ledge. Wet tails can't glide, so the carry
## over the dye must go between sprays. On the far side a second shower guards the gel:
## soaked, the pompadour just bounces off it - go back to the dryer before the shower,
## dry off, and cross between sprays.
func _room_2() -> RoomBuilder:
	var rb := RoomBuilder.new(self, room_node("Room2", "2 - Shampoo Station", Color("e2f1f4")))
	rb.solid(0, 19, 8, 22)        # start floor
	rb.solid(9, 17, 11, 22)       # take-off ledge (2 up)
	rb.dye_pool("DyePool", 12, 20, 10, 2)
	rb.solid(12, 22, 21, 22)
	rb.solid(22, 19, 38, 22)      # landing
	rb.spawn(1, 2, 19)
	rb.spawn(2, 4, 19)
	rb.shower("TakeOffShower", 8, 1, 4, 16, 1.8, 1.6)
	rb.dryer("DryingDryer", 22, 12, 2, 18)
	rb.shower("RinseCurtain", 25, 1, 3, 18, 1.8, 1.6, 0.9)
	rb.gel_wall("GelWall", 33, 13, 2, 6)
	rb.exit(36, 16)
	rb.hint("Wet tails can't glide!\nGo between sprays", Vector2(40, 330))
	rb.hint("A soggy pompadour can't smash gel.\nDry off, then cross between sprays", Vector2(700, 300))
	return rb


## Room 3: everything together. Hair-copter up the dryer before the shower over its top
## soaks you; on the ledge, drink the tonic, dry off, smash the gel, and parry the
## scissor dispenser that the gel was shielding you from.
func _room_3() -> RoomBuilder:
	var rb := RoomBuilder.new(self, room_node("Room3", "3 - Rinse & Repeat", Color("f3e6f4")))
	rb.solid(0, 19, 38, 22)
	rb.spawn(1, 2, 19)
	rb.spawn(2, 4, 19)
	rb.dryer("LiftDryer", 10, 3, 2, 18)
	rb.shower("TopShower", 9, 1, 4, 5, 2.2, 1.4)
	rb.solid(14, 9, 38, 18)       # upper ledge, 10 up (solid to the floor)
	rb.tonic("Tonic", 17, 8)
	rb.dryer("LedgeDryer", 24, 5, 2, 8)
	rb.gel_wall("GelWall", 30, 3, 2, 6)
	rb.turret("Dispenser", 38, 8, Vector2.LEFT, 2.5, 1.0)
	rb.exit(34, 6)
	rb.hint("Ride up before the shower soaks you", Vector2(40, 330))
	return rb
