extends LevelBuilder
## Generates the greybox L1 "Fresh Cut": res://scenes/levels/level_01.tscn.
## Teaches each haircut's skill, then the carry and launch, then twists the carry into
## the Sling Dash (docs/design/refinement.md). No enemies.
## Rerunning OVERWRITES the scene (see LevelBuilder).
## Run: godot --headless --path . --script res://tools/build_level_01.gd


const CURTAIN_REGROW := 2.0
const BG := "res://assets/art/l1/%s.png"


func _configure() -> void:
	level_name = "Level01"
	level_title = "LEVEL 1 - Fresh Cut"
	next_level = "res://scenes/levels/level_02.tscn"
	scene_path = "res://scenes/levels/level_01.tscn"
	tile_atlas = "res://assets/art/l1/tiles_salon.png"
	tileset_path = "res://assets/art/l1/salon_tileset.tres"


func _rooms() -> Array:
	return [_room_1(), _room_2(), _room_3()]


## Room 1: each friend learns their own move, and needs the other once.
func _room_1() -> RoomBuilder:
	var rb := RoomBuilder.new(self, room_node("Room1", "1 - Mirror, Mirror", Color("f3e3d3"), BG % "bg_l1_01_mirror"))
	rb.solid(0, 19, 7, 22)      # start floor
	rb.solid(8, 17, 11, 22)     # step
	rb.solid(12, 15, 21, 22)    # plateau
	rb.solid(22, 18, 23, 22)    # pit: step back up
	rb.solid(24, 19, 31, 22)    # pit: safe floor (pit is 10 wide: glide yes, carry/jump no)
	rb.solid(32, 15, 38, 22)    # far side
	rb.spawn(1, 3, 19)
	rb.spawn(2, 5, 19)
	rb.gel_wall("GelWall", 17, 10, 2, 5)
	var lever := rb.lever("Lever", 34, 14)
	rb.block("Bridge", 22, 9, 10, 1, Vector2i(0, 6), lever)
	rb.exit(36, 12)
	rb.hint("P1:  A / D move   W jump        Twin-Tails ({tt}): HOLD {tt.skill} to glide", Vector2(48, 290))
	rb.hint("P2:  arrow keys move & jump    Pompadour ({pomp}): {pomp.skill} to dash", Vector2(48, 318))
	rb.hint("Hair-gel wall!\n{pomp}: dash into it with  {pomp.skill}", Vector2(380, 236))
	rb.hint("Too far for {pomp}...\n{tt}: jump, then HOLD {tt.skill} to glide", Vector2(740, 190))
	rb.hint("{tt}: press {tt.skill}\nat the lever", Vector2(1040, 300))
	rb.gate("Gel wall", ["dash_gel"])
	rb.gate("10-wide pit to the lever", ["glide"], {"gap": 10, "drop": 0})
	rb.gate("Bridge lever", ["lever"])
	return rb


## Room 2: teach both combos - carry over the dye, launch up the cliff.
func _room_2() -> RoomBuilder:
	var rb := RoomBuilder.new(self, room_node("Room2", "2 - The Washing Basin", Color("d6eef2"), BG % "bg_l1_02_washing_basin"))
	rb.solid(0, 19, 6, 22)      # start floor
	rb.solid(7, 17, 11, 22)     # take-off ledge (2 up)
	rb.solid(20, 19, 26, 22)    # landing
	rb.solid(27, 13, 38, 22)    # cliff (6 up)
	rb.dye_pool("DyePool", 12, 20, 8, 2)
	rb.spawn(1, 2, 19)
	rb.spawn(2, 4, 19)
	var lever := rb.lever("Lever", 30, 12)
	rb.block("RisingStep", 25, 19, 2, 3, Vector2i(0, -3), lever, true)
	rb.exit(36, 10)
	rb.hint("Deadly hair dye!\n{tt}: stand next to {pomp} and HOLD {tt.skill} to grab,\nthen jump from the high ledge", Vector2(40, 330))
	rb.hint("^ take off here", Vector2(236, 500))
	rb.hint("Too high!\nA Pompadour launches whoever\nstands on its head:  {pomp.skill}", Vector2(612, 420))
	rb.hint("{tt}: {tt.skill} pulls the lever", Vector2(880, 300))
	rb.gate("8-wide dye pool, both friends", ["carry"], {"gap": 8, "drop": 2})
	rb.gate("6-up cliff", ["launch"], {"rise": 6})
	rb.gate("Step lever", ["lever"])
	return rb


## Room 3: twist - the Sling Dash. A gel curtain hangs from the ceiling into a wide dye
## pool and grows back 2 s after it's smashed. The pair's carry flight runs into it, so
## pompadour (hanging) must press skill to be flung through it; twin-tails, suddenly
## lighter, bobs up and glides through the hole before it closes.
## Metrics: carry from 6 up reaches ~16 tiles; the fling covers 7.1 tiles flat, so
## flinging anywhere from x=18 to the curtain lands on the far side (a ~0.5 s window).
func _room_3() -> RoomBuilder:
	var rb := RoomBuilder.new(self, room_node("Room3", "3 - The Gel Curtain", Color("efe0f0"), BG % "bg_l1_03_gel_curtain"))
	rb.solid(0, 19, 8, 22)      # start floor
	rb.solid(9, 17, 10, 22)     # stairs up to the take-off counter
	rb.solid(11, 15, 12, 22)
	rb.solid(13, 13, 16, 22)    # take-off counter (6 up)
	rb.solid(25, 15, 38, 22)    # landing, right behind the curtain
	rb.dye_pool("DyePool", 17, 20, 8, 2)
	rb.spawn(1, 2, 19)
	rb.spawn(2, 4, 19)
	# Ceiling to the dye: no way over or under it.
	rb.gel_wall("GelCurtain", 23, 1, 2, 19, CURTAIN_REGROW)
	rb.exit(36, 12)
	rb.hint("This gel grows back!", Vector2(600, 40))
	rb.gate("Regrowing gel curtain over dye", ["sling"])
	rb.hint("{pomp} hanging from {tt}'s hair:
press  {pomp.skill}  to get flung through", Vector2(40, 330))
	return rb
