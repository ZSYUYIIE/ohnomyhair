class_name LevelBuilder
extends SceneTree
## Shared greybox level generator. Each tools/build_level_XX.gd extends this, fills in
## the level fields in _configure() and returns its rooms from _rooms().
## Generated scenes are normal .tscn files; rerunning a builder OVERWRITES its scene,
## so once a level is hand-edited in the editor, edit it there instead.
##
## Coordinates are in tiles (32px), local to each 40x23-tile room (row 22 is half
## off-screen). Measured metrics to size gaps against (tools/measure_metrics.gd):
##   jump: 3.56 high, 6.2 flat / 7.0 landing 2 lower / 8.1 landing 6 lower
##   glide: 12.5 flat     carry: 8.9 flat / 11.4 two lower / 16.5 six lower
##   launch: rider rises 8 tiles above the launcher's head     dash: 5.2

const TILE := 32
const COLS := 40
const ROWS := 23
const TILESET_PATH := "res://assets/tiles/greybox_tileset.tres"
const HINT_COLOR := Color("3b3240")
const EMPTY := 0
const SOLID := 1
const ONE_WAY := 2

var LeverScene := load("res://scenes/props/lever.tscn")
var BlockScene := load("res://scenes/props/moving_block.tscn")
var WallScene := load("res://scenes/props/breakable_wall.tscn")
var HazardScene := load("res://scenes/props/hazard.tscn")
var SpikesScene := load("res://scenes/props/periodic_spikes.tscn")
var ExitScene := load("res://scenes/props/room_exit.tscn")
var PlayerScene := load("res://scenes/player/player.tscn")

var level_root: Node2D
var level_name := "Level"
var level_title := ""
var next_level := ""
var scene_path := ""


## Override: set level_name, level_title, next_level, scene_path.
func _configure() -> void:
	pass


## Override: return an Array of RoomBuilder, left to right.
func _rooms() -> Array:
	return []


class RoomBuilder:
	var b: LevelBuilder
	var node: Node2D
	var grid: Array[PackedByteArray] = []

	func _init(builder: LevelBuilder, room: Node2D) -> void:
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
		_fill(x0, y0, x1, y1, SOLID)

	## Jump-through platform, one tile thick.
	func one_way(x0: int, x1: int, row: int) -> void:
		_fill(x0, row, x1, row, ONE_WAY)

	## Load an ASCII map ('#' solid, '=' one-way, anything else empty). Rows may be
	## shorter than the room; the border stays solid either way.
	func ascii(rows: Array) -> void:
		for y in rows.size():
			var line: String = rows[y]
			for x in mini(line.length(), COLS):
				if line[x] == "#":
					grid[y][x] = SOLID
				elif line[x] == "=":
					grid[y][x] = ONE_WAY

	func _fill(x0: int, y0: int, x1: int, y1: int, value: int) -> void:
		for y in range(y0, y1 + 1):
			for x in range(x0, x1 + 1):
				grid[y][x] = value

	func add(n: Node, name: String) -> Node:
		n.name = name
		node.add_child(n)
		return n

	## Player spawn: feet on top of tile row `floor_row`.
	func spawn(player_id: int, col: int, floor_row: int) -> void:
		var m := Marker2D.new()
		m.position = Vector2(col * TILE + TILE / 2, floor_row * TILE - Player.HALF_SIZE.y)
		add(m, "SpawnP%d" % player_id)

	func exit(col: int, row: int, w := 2, h := 3) -> void:
		var e: Node2D = b.ExitScene.instantiate()
		e.position = Vector2(col, row) * TILE
		e.size = Vector2(w, h) * TILE
		add(e, "Exit")

	func lever(name: String, col: int, row: int, spring_time := 0.0) -> Node2D:
		var l: Node2D = b.LeverScene.instantiate()
		l.position = Vector2(col, row) * TILE + Vector2(TILE, TILE) / 2
		if spring_time > 0.0:
			l.spring_time = spring_time
			l.one_shot = false
		return add(l, name)

	func block(name: String, col: int, row: int, w: int, h: int, offset: Vector2i, trigger: Node, behind_tiles := false) -> Node2D:
		var m: Node2D = b.BlockScene.instantiate()
		m.position = Vector2(col, row) * TILE
		m.size = Vector2(w, h) * TILE
		m.move_offset = Vector2(offset) * TILE
		m.trigger = trigger
		if behind_tiles:
			m.z_index = -1
		return add(m, name)

	func gel_wall(name: String, col: int, row: int, w: int, h: int) -> Node2D:
		var g: Node2D = b.WallScene.instantiate()
		g.position = Vector2(col, row) * TILE
		g.size = Vector2(w, h) * TILE
		return add(g, name)

	func dye_pool(name: String, col: int, row: int, w: int, h: int) -> Node2D:
		var h_node: Node2D = b.HazardScene.instantiate()
		h_node.position = Vector2(col, row) * TILE
		h_node.size = Vector2(w, h) * TILE
		return add(h_node, name)

	## Spikes sit on top of the floor tile row `floor_row`.
	func spikes(name: String, col: int, floor_row: int, w: int) -> Node2D:
		var s: Node2D = b.SpikesScene.instantiate()
		s.size = Vector2(w * TILE, 24)
		s.position = Vector2(col * TILE, floor_row * TILE - 24)
		return add(s, name)

	func turret(name: String, col: int, row: int, direction: Vector2, interval := 2.5, first_delay := 1.0) -> Node2D:
		var t := ScissorTurret.new()
		t.position = _center(col, row)
		t.direction = direction
		t.interval = interval
		t.first_shot_delay = first_delay
		return add(t, name)

	## Clipper bot standing on tile row `floor_row`, patrolling +-patrol_tiles.
	func clipper(name: String, col: int, floor_row: int, patrol_tiles := 3.0) -> Node2D:
		var c := ClipperBot.new()
		c.position = Vector2(col * TILE + TILE / 2, floor_row * TILE)
		c.patrol_range = patrol_tiles * TILE
		return add(c, name)

	func deflector(name: String, col: int, row: int) -> Node2D:
		var d := Deflector.new()
		d.position = _center(col, row)
		return add(d, name)

	func hit_switch(name: String, col: int, row: int) -> Node2D:
		var s := HitSwitch.new()
		s.position = _center(col, row)
		return add(s, name)

	func door(name: String, col: int, row: int, w: int, h: int) -> Node2D:
		var d := Door.new()
		d.position = Vector2(col, row) * TILE
		d.size = Vector2(w, h) * TILE
		return add(d, name)

	## Persistent signal connection, saved into the scene (visible in the Node dock).
	func link(from: Node, signal_name: String, to: Node, method: String) -> void:
		from.connect(signal_name, Callable(to, method), CONNECT_PERSIST)

	## Yellow floor stripes marking a spot (drawn on top of tile row `row`).
	func stripes(name: String, col0: int, col1: int, row: int) -> void:
		var holder := Node2D.new()
		add(holder, name)
		var x := col0 * TILE
		while x < (col1 + 1) * TILE:
			var r := ColorRect.new()
			r.position = Vector2(x, row * TILE)
			r.size = Vector2(10, 6)
			r.color = Color("f1c40f")
			r.mouse_filter = Control.MOUSE_FILTER_IGNORE
			holder.add_child(r)
			x += 20

	func hint(text: String, pos: Vector2) -> void:
		var label := Label.new()
		label.text = text
		label.position = pos
		label.add_theme_color_override("font_color", HINT_COLOR)
		label.add_theme_font_size_override("font_size", 18)
		add(label, "Hint%d" % node.get_child_count())

	func _center(col: int, row: int) -> Vector2:
		return Vector2(col, row) * TILE + Vector2(TILE, TILE) / 2


func _initialize() -> void:
	_configure()
	var tileset := _make_tileset()

	level_root = Node2D.new()
	level_root.name = level_name
	level_root.set_script(load("res://scenes/systems/level.gd"))
	level_root.level_title = level_title
	level_root.next_level = next_level

	var tiles := TileMapLayer.new()
	tiles.name = "Tiles"
	tiles.tile_set = tileset
	own(level_root, tiles)

	var rooms := Node2D.new()
	rooms.name = "Rooms"
	own(level_root, rooms)

	var builders := _rooms()
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
		p.hair = Player.Hair.TWIN_TAILS if id == 1 else Player.Hair.POMPADOUR
		own(players, p)

	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	own(level_root, camera)

	_build_ui()

	var packed := PackedScene.new()
	var err := packed.pack(level_root)
	if err == OK:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(scene_path.get_base_dir()))
		err = ResourceSaver.save(packed, scene_path)
	print(scene_path, " -> ", error_string(err))
	level_root.free()
	quit(err)


func room_node(name: String, title: String, backdrop_color: Color) -> Node2D:
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


func own(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = level_root


## Room children were added before the room joined the level; point them at the root now.
func _reown(node: Node) -> void:
	for child in node.get_children():
		child.owner = level_root
		if child.scene_file_path == "":
			_reown(child)


func _paint(tiles: TileMapLayer, grid: Array[PackedByteArray], col_offset: int) -> void:
	for y in ROWS:
		for x in COLS:
			var cell := Vector2i(col_offset + x, y)
			match grid[y][x]:
				SOLID:
					var surface := y == 0 or grid[y - 1][x] != SOLID
					tiles.set_cell(cell, 0, Vector2i(0 if surface else 1, 0))
				ONE_WAY:
					tiles.set_cell(cell, 0, Vector2i(2, 0))


func _print_ascii(rb: RoomBuilder) -> void:
	print("\n", rb.node.name, "  ", rb.node.title)
	for y in ROWS:
		var line := ""
		for x in COLS:
			line += ".#="[rb.grid[y][x]]
		print(line)


func _make_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, Layers.WORLD)
	ts.set_physics_layer_collision_mask(0, 0)
	var src := TileSetAtlasSource.new()
	src.texture = load("res://assets/tiles/greybox_tiles.png")
	src.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(src, 0)
	var h := TILE / 2.0
	var square := PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)])
	var lip := PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, -h + 8), Vector2(-h, -h + 8)])
	for x in 3:
		var coords := Vector2i(x, 0)
		src.create_tile(coords)
		var data := src.get_tile_data(coords, 0)
		data.add_collision_polygon(0)
		data.set_collision_polygon_points(0, 0, lip if x == 2 else square)
		data.set_collision_polygon_one_way(0, 0, x == 2)
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
