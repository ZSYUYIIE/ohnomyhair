extends Node2D
## L2 "Scissor Corridor". Built at runtime from the tile map in docs/levels/level_02.md:
## keep MAP in sync with that doc. 16 px tiles, row 0 at the top.

const TILE := 16
const MAP: Array[String] = [
	"########################################",
	"#...........................S..........#",
	"#......................................#",
	"#......................................#",
	"#......................................#",
	"#......................................#",
	"#....................L.................#",
	"#................======................#",
	"#......................................#",
	"#......................................#",
	"#......................................#",
	"#......................................#",
	"#......................................#",
	"#......................................#",
	"#...........................D.........T#",
	"#................##################....#",
	"#..............k.#......|..............#",
	"#..............###......|..............#",
	"#..............###......|..........====#",
	"#............#####.EEEE.|..............#",
	"#.12....c....#####.EEEE.|..............#",
	"########################################",
]
const LEVER_SPRING_TIME := 1.2

const SOLID_COLOR := Color("3b3355")
const SOLID_EDGE := Color("5a4f7c")
const ONE_WAY_COLOR := Color("9b87c9")
const EXIT_COLOR := Color(0.18, 0.8, 0.44, 0.35)

var _solid_rects: Array[Rect2] = []
var _one_way_rects: Array[Rect2] = []
var _exit_rect: Rect2
var _checkpoint := Vector2.ZERO


func _ready() -> void:
	_build_terrain()
	_spawn_entities()
	_add_signs()
	add_child(Hud.new())
	var spawn := (_floor_pos(_cells("1")[0]) + _floor_pos(_cells("2")[0])) / 2
	Game.start_level(spawn)


func _physics_process(_delta: float) -> void:
	var players := get_tree().get_nodes_in_group("players")
	var all_in_exit := not players.is_empty()
	for p in players:
		if p.global_position.distance_to(_checkpoint) < 16.0:
			Game.checkpoint = _checkpoint
		if not _exit_rect.has_point(p.global_position - Vector2(0, 1)):
			all_in_exit = false
	if all_in_exit:
		Game.win()


# --- building --------------------------------------------------------------

func _build_terrain() -> void:
	var solid := _static_body()
	var one_way := _static_body()
	for y in MAP.size():
		var row := MAP[y]
		var x := 0
		while x < row.length():
			var tile := row[x]
			if tile != "#" and tile != "=":
				x += 1
				continue
			var start := x
			while x < row.length() and row[x] == tile:
				x += 1
			var rect := Rect2(start * TILE, y * TILE, (x - start) * TILE, TILE)
			var shape := Player._add_rect_shape(solid if tile == "#" else one_way, rect.size, rect.get_center())
			if tile == "=":
				shape.one_way_collision = true
				_one_way_rects.append(rect)
			else:
				_solid_rects.append(rect)


func _spawn_entities() -> void:
	_add_player(1, TwinTails.new(), Color("e8508a"), _floor_pos(_cells("1")[0]))
	_add_player(2, Pompadour.new(), Color("f2a93b"), _floor_pos(_cells("2")[0]))

	for cell in _cells("c"):
		var bot := ClipperBot.new()
		bot.position = _floor_pos(cell)
		add_child(bot)

	var turret := ScissorTurret.new()
	turret.position = _center_pos(_cells("T")[0])
	turret.direction = Vector2.LEFT
	add_child(turret)

	var deflector := Deflector.new()
	deflector.position = _center_pos(_cells("D")[0])
	add_child(deflector)

	var lever := Lever.new()
	lever.position = _floor_pos(_cells("L")[0])
	lever.spring_time = LEVER_SPRING_TIME
	add_child(lever)
	lever.activated.connect(deflector.raise)
	lever.deactivated.connect(deflector.lower)

	var door_cells := _cells("|")
	var door := Door.new()
	door.position = Vector2(door_cells[0]) * TILE
	door.size = Vector2(TILE, door_cells.size() * TILE)
	add_child(door)

	var hit_switch := HitSwitch.new()
	hit_switch.position = _center_pos(_cells("S")[0])
	add_child(hit_switch)
	hit_switch.activated.connect(door.open)

	_checkpoint = _floor_pos(_cells("k")[0])
	var exit_cells := _cells("E")
	_exit_rect = Rect2(Vector2(exit_cells[0]) * TILE, Vector2.ZERO)
	for cell in exit_cells:
		_exit_rect = _exit_rect.expand(Vector2(cell + Vector2i.ONE) * TILE)


func _add_player(id: int, hair: HairAbility, body_color: Color, at: Vector2) -> void:
	var p := Player.new()
	p.player_id = id
	p.ability = hair
	p.color = body_color
	p.position = at
	add_child(p)


func _add_signs() -> void:
	_sign(Vector2(24, 24), "P1  A/D move   W jump   F glide + pull lever   G hair whip")
	_sign(Vector2(24, 36), "P2  Arrows move   Up jump   K dash / launch   L parry")
	_sign(Vector2(230, 150), "P1 stand on P2's head, P2 press K")


func _sign(at: Vector2, text: String) -> void:
	var label := Label.new()
	label.position = at
	label.text = text
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	add_child(label)


func _static_body() -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	add_child(body)
	return body


func _cells(tile: String) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for y in MAP.size():
		for x in MAP[y].length():
			if MAP[y][x] == tile:
				found.append(Vector2i(x, y))
	return found


func _center_pos(cell: Vector2i) -> Vector2:
	return Vector2(cell) * TILE + Vector2(TILE, TILE) / 2


## Standing position for something whose feet rest on the bottom of this cell.
func _floor_pos(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, (cell.y + 1) * TILE)


func _draw() -> void:
	draw_rect(_exit_rect, EXIT_COLOR)
	for rect in _solid_rects:
		draw_rect(rect, SOLID_COLOR)
		draw_rect(rect, SOLID_EDGE, false, 1.0)
	for rect in _one_way_rects:
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 4)), ONE_WAY_COLOR)
	draw_rect(Rect2(_checkpoint + Vector2(-1, -16), Vector2(2, 16)), Color("bdc3c7"))
	draw_rect(Rect2(_checkpoint + Vector2(1, -16), Vector2(7, 5)), Color("2ecc71") if Game.checkpoint == _checkpoint else Color("7f8c8d"))
	draw_string(ThemeDB.fallback_font, _exit_rect.position + Vector2(18, -4), "EXIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 8)


func _process(_delta: float) -> void:
	queue_redraw()
