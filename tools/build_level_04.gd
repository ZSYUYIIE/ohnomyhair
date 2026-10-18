extends LevelBuilder
## Generates L4 "Perm Day": res://scenes/levels/level_04.tscn.
## P1's twin-tails got permed: the pair is Afro (P1) + Pompadour (P2). No lever puller in
## this pair, so every switch is a bell, and every height is a spring
## (docs/design/roster_and_chapters.md, docs/levels/level_04.md).
## Room 1 teaches the spring (a launch is 2 tiles short), room 2 the cannonball through
## gel that sets again, room 3 the double return (parry, catch, send it the other way).
## Rerunning OVERWRITES the scene (see LevelBuilder).
## Run: godot --headless --path . --script res://tools/build_level_04.gd

const ORANGE := Color("ee9a42")


func _configure() -> void:
	level_name = "Level04"
	level_title = "LEVEL 4 - Perm Day"
	next_level = "res://scenes/levels/level_05.tscn"
	scene_path = "res://scenes/levels/level_04.tscn"
	tile_atlas = "res://assets/art/l2/tiles_l2.png"
	tileset_path = "res://assets/art/l2/perm_tileset.tres"
	pair = [Player.Hair.AFRO, Player.Hair.POMPADOUR]


func _rooms() -> Array:
	return [_room_1(), _room_2(), _room_3()]


## Room 1: the roller shelf is 11 up. A pompadour launch lifts the afro 9 tiles (short);
## a charged afro springs the pompadour 12-13 (enough). Up there, P2 parries a scissor
## into the bell, the staff door opens, and P2 drops back down to leave together.
func _room_1() -> RoomBuilder:
	var rb := RoomBuilder.new(self, room_node("Room1", "1 - The Perm Rollers", Color("f3e3d3"), "res://assets/art/l1/bg_l1_01_mirror.png"))
	rb.solid(0, 19, 38, 22)
	rb.one_way(13, 29, 8)       # roller shelf, 11 up: spring from underneath, drop back down
	# A lip stops the dispenser's scissors, so the landing end of the shelf (and the
	# rider flying up past it) stays safe; hop over it to parry.
	rb.solid(18, 6, 18, 7)
	rb.solid(30, 1, 30, 14)     # wall over the staff door
	rb.spawn(1, 3, 19)
	rb.spawn(2, 5, 19)
	rb.turret("Dispenser", 29, 7, Vector2.LEFT, 2.5, 1.0)
	var bell := rb.hit_switch("Bell", 24, 7)
	var door := rb.door("StaffDoor", 30, 15, 1, 4)
	rb.link(bell, "activated", door, "open")
	rb.stripes("ParryStripes", 19, 22, 8)
	rb.exit(35, 16)
	rb.gate("Roller shelf 11 up", ["spring", "hook", "hair_copter"])
	rb.gate("Bell on the shelf", ["parry", "catch_return"])
	rb.hint("{afro}: HOLD {afro.skill} to wind your perm up like a spring.\nLet go, and whoever stands on your head goes sky-high.", Vector2(48, 300))
	rb.hint("A Pompadour launch won't reach.\nA wound-up Afro will.", Vector2(470, 420))
	rb.hint("{pomp}: parry ({pomp.attack}) a scissor into the bell", Vector2(470, 150))
	return rb


## Room 2: orange (perm-set) gel fills the room ceiling to floor and sets again 2.5 s after
## it breaks. A plain dash bounces off; the cannonball (13.8 tiles flat, so the afro must
## stand past 6.7 tiles, under the shower) punches through,
## and the afro runs through the hole before it closes. The shower over the approach
## soaks the afro (no spring while wet): go between sprays, or dry off at the dryer.
func _room_2() -> RoomBuilder:
	var rb := RoomBuilder.new(self, room_node("Room2", "2 - Setting Lotion", Color("fbe9de"), "res://assets/art/l3/bg_l3_01_blow_dry.png"))
	rb.solid(0, 19, 38, 22)
	rb.spawn(1, 3, 19)
	rb.spawn(2, 5, 19)
	rb.dryer("Dryer", 1, 12, 2, 18)
	# Every spot a cannonball clears the gel from (afro past 6.7 tiles) is under the shower.
	rb.shower("Rinse", 6, 1, 12, 18, 2.4, 1.4)
	var gel := rb.gel_wall("PermGel", 18, 1, 2, 18, 2.5)
	gel.requires_cannonball = true
	rb.exit(35, 16)
	rb.gate("Perm-set gel that sets again", ["cannonball"])
	rb.gate("Shower over the approach", ["walk"])
	rb.hint("Orange gel is perm-set:\na plain dash just bounces off.", Vector2(700, 150))
	rb.hint("{pomp}: stand on {afro}'s head and HOLD {pomp.skill}\nwhile {afro} lets go of {afro.skill}: CANNONBALL!", Vector2(220, 60))
	rb.hint("Wet perms won't spring.\nDry off in the warm air.", Vector2(40, 260))
	rb.hint("Run through\nbefore it sets!", Vector2(700, 420))
	return rb


## Room 3: a dispenser on the left wall fires right along the body line. The left bell
## (behind the dispenser's line) rings from a plain parry. The right bell is past the
## friends: only a scissor caught by the afro in the trench and released facing right
## can get there. The staff door needs both.
func _room_3() -> RoomBuilder:
	var rb := RoomBuilder.new(self, room_node("Room3", "3 - Double Return", Color("dfe7f2"), "res://assets/art/l2/bg_l2_02_corridor.png"))
	rb.solid(0, 19, 11, 22)
	rb.solid(13, 19, 38, 22)
	rb.solid(12, 21, 12, 22)    # catch trench at x=12, 2 deep: scissors fly over the afro in it
	rb.solid(34, 1, 34, 14)     # wall over the staff door
	rb.spawn(1, 20, 19)
	rb.spawn(2, 22, 19)
	rb.turret("Dispenser", 1, 18, Vector2.RIGHT, 2.5, 2.5)
	var left_bell := rb.hit_switch("LeftBell", 4, 18)
	var right_bell := rb.hit_switch("RightBell", 31, 18)
	var door := rb.door("StaffDoor", 34, 15, 1, 4, 2)
	rb.link(left_bell, "activated", door, "open")
	rb.link(right_bell, "activated", door, "open")
	rb.stripes("ParryStripes", 15, 17, 19)
	rb.stripes("CatchMark", 12, 12, 21, ORANGE)
	rb.exit(36, 16)
	rb.gate("Dispenser on the body line", ["parry", "shield"])
	rb.gate("Bell behind the dispenser line", ["parry"])
	rb.gate("Bell past the friends", ["catch_return"])
	rb.hint("Two bells. The door needs both.", Vector2(560, 200))
	rb.hint("{pomp}: parry ({pomp.attack}) on the yellow stripes", Vector2(380, 420))
	rb.hint("{afro}: wait in the trench, HOLD {afro.attack} to catch a BLUE scissor,\nturn around, and let go: it flies back the other way!", Vector2(40, 330))
	return rb
