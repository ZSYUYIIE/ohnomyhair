extends SceneTree
## Generates the greybox L1: res://scenes/levels/level_01.tscn (+ the shared tileset).
## Rerunning OVERWRITES level_01.tscn. Once the level is hand-edited in the
## editor, edit it there and stop using this script.
## Run: godot --headless --path . --script res://tools/build_level_01.gd
##
## Coordinates below are in tiles (32px), local to each 40x23-tile room.
## Measured metrics these gaps were sized against (rerun tools/measure_metrics.gd
## after changing movement), as gap clearable from a running take-off:
##   jump: 3.56 high, 6.2 flat / 7.0 landing 2 lower / 8.1 landing 6 lower
##   glide: 12.5 flat     carry: 8.9 flat / 11.4 two lower / 16.5 six lower
##   launch: rider's feet peak 8.1 above the floor     dash: 5.2

const TILE := 32
const COLS := 40
const ROWS := 23
const TILESET_PATH := "res://assets/tiles/greybox_tileset.tres"
const SCENE_PATH := "res://scenes/levels/level_01.tscn"
const HINT_COLOR := Color("3b3240")

var LeverScene := load("res://scenes/props/lever.tscn")
var BlockScene := load("res://scenes/props/moving_block.tscn")
var WallScene := load("res://scenes/props/breakable_wall.tscn")
var HazardScene := load("res://scenes/props/hazard.tscn")
var SpikesScene := load("res://scenes/props/periodic_spikes.tscn")
var ExitScene := load("res://scenes/props/room_exit.tscn")
var PlayerScene := load("res://scenes/player/player.tscn")

var level_root: Node2D


class RoomBuilder:
	var b  # the SceneTree script, for helpers
	var node: Node2D
	var grid: Array[PackedByteArray] = []

	func _init(builder, room: Node2D) -> void:
		b = builder
		node = room
		for y in ROWS:
			var row := PackedByteArray()
			row.resize(COLS)
			grid.append(row)
		solid(0, 0, COLS - 1, 0)
		solid(0, 0, 0, ROWS - 1)
		solid(COLS - 1, 0, COLS - 1, ROWS - 1)
		solid(0, ROWS - 1, COLS - 1, ROWS - 1)

	## Fill tiles x0..x1, y0..y1 (inclusive).
	func solid(x0: int, y0: int, x1: int, y1: int) -> void:
		for y in range(y0, y1 + 1):
			for x in range(x0, x1 + 1):
				grid[y][x] = 1

	func spawn(player_id: int, col: int, floor_row: int) -> void:
		var m := Marker2D.new()
		m.name = "SpawnP%d" % player_id
		m.position = Vector2(col * TILE + TILE / 2, floor_row * TILE - Player.HALF_SIZE.y)
		node.add_child(m)

	func exit(col: int, row: int) -> void:
		var e: Node2D = b.ExitScene.instantiate()
		e.name = "Exit"
		e.position = Vector2(col, row) * TILE
		node.add_child(e)

	func lever(name: String, col: int, row: int) -> Node2D:
		var l: Node2D = b.LeverScene.instantiate()
		l.name = name
		l.position = Vector2(col, row) * TILE + Vector2(TILE, TILE) / 2
		node.add_child(l)
		return l

	func block(name: String, col: int, row: int, w: int, h: int, offset: Vector2i, trigger: Node, behind_tiles := false) -> void:
		var m: Node2D = b.BlockScene.instantiate()
		m.name = name
		m.position = Vector2(col, row) * TILE
		m.size = Vector2(w, h) * TILE
		m.move_offset = Vector2(offset) * TILE
		m.trigger = trigger
		if behind_tiles:
			m.z_index = -1
		node.add_child(m)

	func gel_wall(name: String, col: int, row: int, w: int, h: int) -> void:
		var g: Node2D = b.WallScene.instantiate()
		g.name = name
		g.position = Vector2(col, row) * TILE
		g.size = Vector2(w, h) * TILE
		node.add_child(g)

	func dye_pool(name: String, col: int, row: int, w: int, h: int) -> void:
		var h_node: Node2D = b.HazardScene.instantiate()
		h_node.name = name
		h_node.position = Vector2(col, row) * TILE
		h_node.size = Vector2(w, h) * TILE
		node.add_child(h_node)

	## Spikes sit on top of the floor tile row `floor_row`.
	func spikes(name: String, col: int, floor_row: int, w: int) -> void:
		var s: Node2D = b.SpikesScene.instantiate()
		s.name = name
		s.size = Vector2(w * TILE, 24)
		s.position = Vector2(col * TILE, floor_row * TILE - 24)
		node.add_child(s)

	func hint(text: String, pos: Vector2) -> void:
		var label := Label.new()
		label.name = "Hint%d" % node.get_child_count()
		label.text = text
		label.position = pos
		label.add_theme_color_override("font_color", HINT_COLOR)
		label.add_theme_font_size_override("font_size", 18)
		node.add_child(label)


func _initialize() -> void:
	var tileset := _make_tileset()

	level_root = Node2D.new()
	level_root.name = "Level01"
	level_root.set_script(load("res://scenes/systems/level.gd"))
	level_root.level_title = "LEVEL 1 - Fresh Cut"
	level_root.next_level = "res://scenes/levels/level_02.tscn"

	var tiles := TileMapLayer.new()
	tiles.name = "Tiles"
	tiles.tile_set = tileset
	own(level_root, tiles)

	var rooms := Node2D.new()
	rooms.name = "Rooms"
	own(level_root, rooms)

	var builders := [_room_1(), _room_2(), _room_3()]
	for i in builders.size():
		var rb: RoomBuilder = builders[i]
		rb.node.position = Vector2(i * COLS * TILE, 0)
		rooms.add_child(rb.node)
		rb.node.owner = level_root
		_reown(rb.node)
		_paint(tiles, rb.grid, i * COLS)
		_print_ascii(rb)

	var players := Node2D.new()
	players.name = "Players"
	own(level_root, players)
	for id in [1, 2]:
		var p: Node2D = PlayerScene.instantiate()
		p.name = "P%d" % id
		p.player_id = id
		p.hair = 0 if id == 1 else 1  # Player.Hair.TWIN_TAILS / POMPADOUR
		own(players, p)

	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	own(level_root, camera)

	_build_ui()

	var packed := PackedScene.new()
	var err := packed.pack(level_root)
	if err == OK:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://scenes/levels"))
		err = ResourceSaver.save(packed, SCENE_PATH)
	print("level_01.tscn -> ", error_string(err))
	level_root.free()
	quit(err)


# --- Rooms --------------------------------------------------------------------

## Room 1: each friend learns their own move, and needs the other once.
func _room_1() -> RoomBuilder:
	var rb := RoomBuilder.new(self, _room_node("Room1", "1 - Mirror, Mirror", Color("f3e3d3")))
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
	rb.hint("P1 Twin-Tails:  A / D move   W jump   HOLD G glide", Vector2(48, 290))
	rb.hint("P2 Pompadour:  arrow keys move & jump   /  dash", Vector2(48, 318))
	rb.hint("Hair-gel wall!\nP2: dash into it with  /", Vector2(380, 236))
	rb.hint("Too far for P2...\nP1: jump, then HOLD G to glide", Vector2(740, 190))
	rb.hint("P1: press G\nat the lever", Vector2(1040, 300))
	return rb


## Room 2: teach both combos - carry over the dye, launch up the cliff.
func _room_2() -> RoomBuilder:
	var rb := RoomBuilder.new(self, _room_node("Room2", "2 - The Washing Basin", Color("d6eef2")))
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
	rb.hint("Deadly hair dye!\nP1: stand next to P2 and HOLD G to grab,\nthen jump from the high ledge", Vector2(40, 330))
	rb.hint("^ take off here", Vector2(236, 500))
	rb.hint("Too high!\nP1 stands on P2's head,\nP2 presses  /  to launch", Vector2(612, 420))
	rb.hint("P1: G pulls the lever", Vector2(880, 300))
	return rb


## Room 3: everything at once, with timed comb spikes for pressure.
func _room_3() -> RoomBuilder:
	var rb := RoomBuilder.new(self, _room_node("Room3", "3 - The Barber's Bench", Color("efe0f0")))
	rb.solid(0, 19, 8, 22)      # start floor
	rb.solid(9, 13, 17, 22)     # high deck (6 up)
	rb.solid(28, 19, 38, 22)    # landing
	rb.dye_pool("DyePool", 18, 20, 10, 2)
	rb.spawn(1, 2, 19)
	rb.spawn(2, 4, 19)
	var lever := rb.lever("Lever", 10, 12)
	rb.block("RisingStep", 7, 19, 2, 3, Vector2i(0, -3), lever, true)
	rb.spikes("CombSpikes", 13, 13, 2)
	rb.gel_wall("GelWall", 33, 13, 2, 6)
	rb.exit(36, 16)
	rb.hint("Everything you learned. Together.", Vector2(40, 330))
	return rb


func _room_node(name: String, title: String, backdrop_color: Color) -> Node2D:
	var room := Node2D.new()
	room.name = name
	room.set_script(load("res://scenes/systems/room.gd"))
	room.title = title
	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.size = Vector2(COLS * TILE, 720)
	backdrop.color = backdrop_color
	backdrop.z_index = -10
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room.add_child(backdrop)
	return room


# --- Helpers ------------------------------------------------------------------

func own(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = level_root


## Room children were added before the room joined level_root; point them at level_root now.
func _reown(node: Node) -> void:
	for child in node.get_children():
		child.owner = level_root
		if child.scene_file_path == "":
			_reown(child)


func _paint(tiles: TileMapLayer, grid: Array[PackedByteArray], col_offset: int) -> void:
	for y in ROWS:
		for x in COLS:
			if grid[y][x] == 0:
				continue
			var surface := y == 0 or grid[y - 1][x] == 0
			tiles.set_cell(Vector2i(col_offset + x, y), 0, Vector2i(0 if surface else 1, 0))


func _print_ascii(rb: RoomBuilder) -> void:
	print("\n", rb.node.name, "  ", rb.node.title)
	for y in ROWS:
		var line := ""
		for x in COLS:
			line += "#" if rb.grid[y][x] else "."
		print(line)


func _make_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)  # "world"
	ts.set_physics_layer_collision_mask(0, 0)
	var src := TileSetAtlasSource.new()
	src.texture = load("res://assets/tiles/greybox_tiles.png")
	src.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(src, 0)
	var half := TILE / 2.0
	var square := PackedVector2Array([Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)])
	for x in 2:
		var coords := Vector2i(x, 0)
		src.create_tile(coords)
		var data := src.get_tile_data(coords, 0)
		data.add_collision_polygon(0)
		data.set_collision_polygon_points(0, 0, square)
	ResourceSaver.save(ts, TILESET_PATH)
	return load(TILESET_PATH)


func _build_ui() -> void:
	var ui := CanvasLayer.new()
	ui.name = "UI"
	own(level_root, ui)

	var flash := ColorRect.new()
	flash.name = "Flash"
	flash.anchor_right = 1.0
	flash.anchor_bottom = 1.0
	flash.color = Color(1, 1, 1, 0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	own(ui, flash)

	var banner := Label.new()
	banner.name = "Banner"
	banner.anchor_right = 1.0
	banner.offset_top = 40.0
	banner.offset_bottom = 150.0
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 34)
	banner.add_theme_color_override("font_color", HINT_COLOR)
	banner.add_theme_color_override("font_outline_color", Color.WHITE)
	banner.add_theme_constant_override("outline_size", 8)
	own(ui, banner)

	var controls := Label.new()
	controls.name = "Controls"
	controls.anchor_top = 1.0
	controls.anchor_bottom = 1.0
	controls.offset_left = 12.0
	controls.offset_top = -30.0
	controls.text = "P1: A/D  W  G      P2: arrows  /      R: restart room"
	controls.add_theme_font_size_override("font_size", 14)
	controls.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	own(ui, controls)
