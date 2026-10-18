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
var IronScene := load("res://scenes/props/hot_iron.tscn")
var ExitScene := load("res://scenes/props/room_exit.tscn")
var PlayerScene := load("res://scenes/player/player.tscn")

var level_root: Node2D
var level_name := "Level"
var level_title := ""
var next_level := ""
var ending_text := ""
var scene_path := ""
## Hand-drawn tiles: a 4x5 atlas from tools/art/make_l1_art.py, where each solid tile is
## picked by which neighbours are solid (inked edges and countertops where it meets air).
## Empty = the greybox tiles. `tileset_path` is where its TileSet is saved.
var tile_atlas := ""
var tileset_path := TILESET_PATH
## The chapter's pair (P1, P2): every room starts with it and its chair offers it
## (docs/design/roster_and_chapters.md). Rooms can override with RoomBuilder.styles().
var pair: Array[int] = [Player.Hair.TWIN_TAILS, Player.Hair.POMPADOUR]


## Override: set level_name, level_title, next_level (or ending_text), scene_path.
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
		node.starting_hair = PackedInt32Array(b.pair)
		node.styles = PackedInt32Array(b.pair)
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

	## regrow > 0: the gel grows back that many seconds after being smashed.
	func gel_wall(name: String, col: int, row: int, w: int, h: int, regrow := 0.0) -> Node2D:
		var g: Node2D = b.WallScene.instantiate()
		g.position = Vector2(col, row) * TILE
		g.size = Vector2(w, h) * TILE
		g.regrow_time = regrow
		return add(g, name)

	func dye_pool(name: String, col: int, row: int, w: int, h: int) -> Node2D:
		var h_node: Node2D = b.HazardScene.instantiate()
		h_node.position = Vector2(col, row) * TILE
		h_node.size = Vector2(w, h) * TILE
		return add(h_node, name)

	## A hot flat iron lying on top of the floor tile row `floor_row`; `phase` offsets its heat cycle.
	func hot_iron(name: String, col: int, floor_row: int, w: int, phase := 0.0) -> Node2D:
		var s: Node2D = b.IronScene.instantiate()
		s.phase = phase
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

	## Hair dryer: warm-air column over tiles col..col+w-1, rows top_row..bottom_row (dryer at the bottom).
	func dryer(name: String, col: int, top_row: int, w: int, bottom_row: int) -> Node2D:
		var d := HairDryer.new()
		d.position = Vector2(col, top_row) * TILE
		d.size = Vector2(w, bottom_row - top_row + 1) * TILE
		return add(d, name)

	## Shampoo shower spraying over tiles col..col+w-1, rows top_row..bottom_row.
	## off_time 0 = always on; otherwise sprays on_time out of every off_time + on_time.
	func shower(name: String, col: int, top_row: int, w: int, bottom_row: int, off_time := 1.8, on_time := 1.6, phase := 0.0) -> Node2D:
		var s := ShowerHead.new()
		s.position = Vector2(col, top_row) * TILE
		s.size = Vector2(w, bottom_row - top_row + 1) * TILE
		s.off_time = off_time
		s.on_time = on_time
		s.phase = phase
		return add(s, name)

	## Growth tonic bottle (+1 hair) centered in a tile.
	func tonic(name: String, col: int, row: int) -> Node2D:
		var t := GrowthTonic.new()
		t.position = _center(col, row)
		return add(t, name)

	## Gold hook ring for Long Straight at room-local pixel `at`. Rings are targets, not floors.
	func ring(name: String, at: Vector2) -> Node2D:
		var r: Node2D = load("res://scenes/props/hair_anchor.gd").new()
		r.position = at
		return add(r, name)

	## Service bell centred in tile (col, row); `x_shift` px moves it sideways, e.g. 16 to
	## hang it over the middle of a 2-wide trench, so a toss from anywhere in it rings.
	func hit_switch(name: String, col: int, row: int, x_shift := 0.0) -> Node2D:
		var s := HitSwitch.new()
		s.position = _center(col, row) + Vector2(x_shift, 0)
		return add(s, name)

	## locks: how many switches must call open() before it opens.
	func door(name: String, col: int, row: int, w: int, h: int, locks := 1) -> Node2D:
		var d := Door.new()
		d.position = Vector2(col, row) * TILE
		d.size = Vector2(w, h) * TILE
		d.locks = locks
		return add(d, name)

	## Persistent signal connection, saved into the scene (visible in the Node dock).
	func link(from: Node, signal_name: String, to: Node, method: String) -> void:
		from.connect(signal_name, Callable(to, method), CONNECT_PERSIST)

	## Floor stripes marking a spot (drawn on top of tile row `row`). Yellow = parry here,
	## pink = twin-tails catches scissors here.
	func stripes(name: String, col0: int, col1: int, row: int, color := Color("f1c40f")) -> void:
		var holder := Node2D.new()
		add(holder, name)
		var x := col0 * TILE
		while x < (col1 + 1) * TILE:
			var r := ColorRect.new()
			r.position = Vector2(x, row * TILE)
			r.size = Vector2(10, 6)
			r.color = color
			r.mouse_filter = Control.MOUSE_FILTER_IGNORE
			holder.add_child(r)
			x += 20

	## Haircuts the room's chair offers (and Tony restyles into). Every distinct pair
	## must pass every gate; `start` is the pair the room starts with.
	func styles(hairs: Array, start: Array = []) -> void:
		node.styles = PackedInt32Array(hairs)
		if start.size() == 2:
			node.starting_hair = PackedInt32Array(start)

	## An obstacle for the gate check, passable with any one of `verbs` (StyleRules).
	## `spec` sizes it for the margin table (tools/difficulty/margins.gd), in tiles:
	## {"gap": width, "drop": take-off height above the landing} or {"rise": height}.
	func gate(name: String, verbs: Array, spec := {}) -> void:
		var entry := {"name": name, "any": PackedStringArray(verbs)}
		if not spec.is_empty():
			entry["spec"] = spec
		node.gates.append(entry)

	## Hints may use haircut tokens ({tt}, {tt.skill}... see HairHint); they resolve
	## at runtime to whoever wears that haircut.
	func hint(text: String, pos: Vector2) -> void:
		var label := Label.new()
		label.text = text
		if "{" in text:
			label.set_script(load("res://scenes/ui/hair_hint.gd"))
			label.template = text
			var worn := {node.starting_hair[0]: 1, node.starting_hair[1]: 2} if node.starting_hair.size() == 2 else {}
			label.text = HairHint.resolve(text, worn)
		label.position = pos
		label.add_theme_color_override("font_color", HINT_COLOR)
		label.add_theme_font_size_override("font_size", 18)
		# A soft paper-coloured halo keeps hints readable over the drawn backgrounds.
		label.add_theme_color_override("font_outline_color", Color(1, 0.98, 0.94, 0.85))
		label.add_theme_constant_override("outline_size", 6)
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
	level_root.ending_text = ending_text

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
		p.hair = pair[id - 1]
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


## `background`: a 1280x720 painted wall for this room; without one the room gets a flat
## `backdrop_color` wall dressed by SalonDecor.
func room_node(name: String, title: String, backdrop_color: Color, background := "") -> Node2D:
	var room := Node2D.new()
	room.name = name
	room.set_script(load("res://scenes/systems/room.gd"))
	room.title = title
	if background != "":
		var wall := TextureRect.new()
		wall.name = "Backdrop"
		wall.texture = load(background)
		wall.z_index = -10
		wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
		room.add_child(wall)
		return room
	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.size = Vector2(COLS * TILE, 720)
	backdrop.color = backdrop_color
	backdrop.z_index = -10
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room.add_child(backdrop)
	var decor := SalonDecor.new()
	decor.name = "Decor"
	decor.size = backdrop.size
	decor.wall_color = backdrop_color
	decor.layout_seed = hash(level_name + name)
	decor.z_index = -9
	room.add_child(decor)
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
					if tile_atlas != "":
						tiles.set_cell(cell, 0, _edge_tile(grid, x, y))
					else:
						var surface := y == 0 or grid[y - 1][x] != SOLID
						tiles.set_cell(cell, 0, Vector2i(0 if surface else 1, 0))
				ONE_WAY:
					tiles.set_cell(cell, 0, Vector2i(3, 4) if tile_atlas != "" else Vector2i(2, 0))


## Atlas cell of a hand-drawn solid tile: its neighbour mask (1 up, 2 right, 4 down,
## 8 left; outside the room counts as solid), or a random-looking variant when enclosed.
func _edge_tile(grid: Array[PackedByteArray], x: int, y: int) -> Vector2i:
	const SIDES: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	var mask := 0
	for i in 4:
		var n := Vector2i(x, y) + SIDES[i]
		if n.x < 0 or n.y < 0 or n.x >= COLS or n.y >= ROWS or grid[n.y][n.x] == SOLID:
			mask |= 1 << i
	var variant := (x * 7 + y * 13) % 4
	if mask == 15 and variant > 0:
		return Vector2i(variant - 1, 4)
	return Vector2i(mask % 4, mask / 4)


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
	ts.add_physics_layer()  # 0: solid tiles
	ts.set_physics_layer_collision_layer(0, Layers.WORLD)
	ts.set_physics_layer_collision_mask(0, 0)
	ts.add_physics_layer()  # 1: one-way platforms (separate layer so players can drop through)
	ts.set_physics_layer_collision_layer(1, Layers.PLATFORMS)
	ts.set_physics_layer_collision_mask(1, 0)
	var src := TileSetAtlasSource.new()
	src.texture = load(tile_atlas if tile_atlas != "" else "res://assets/tiles/greybox_tiles.png")
	src.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(src, 0)
	var h := TILE / 2.0
	var square := PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)])
	var lip := PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, -h + 8), Vector2(-h, -h + 8)])
	# Greybox: surface, interior, one-way in a row. Hand-drawn: 16 masks + 3 variants, then one-way.
	var coords_list: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	var one_way := Vector2i(2, 0)
	if tile_atlas != "":
		coords_list.clear()
		for i in 20:
			coords_list.append(Vector2i(i % 4, i / 4))
		one_way = Vector2i(3, 4)
	for coords in coords_list:
		src.create_tile(coords)
		var data := src.get_tile_data(coords, 0)
		var is_lip := coords == one_way
		var layer := 1 if is_lip else 0
		data.add_collision_polygon(layer)
		data.set_collision_polygon_points(layer, 0, lip if is_lip else square)
		data.set_collision_polygon_one_way(layer, 0, is_lip)
	ResourceSaver.save(ts, tileset_path)
	return load(tileset_path)


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
