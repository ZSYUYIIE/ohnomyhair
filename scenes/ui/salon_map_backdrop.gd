extends Control
## Vector road and lock decorations under real stage Buttons. No baked UI hit areas.
const STOPS := [Vector2(220, 440), Vector2(530, 265), Vector2(835, 365), Vector2(1140, 265)]
var selected := 0
var unlocked: Array[bool] = []
var _road := PackedVector2Array()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var curve := Curve2D.new()
	curve.add_point(STOPS[0], Vector2.ZERO, Vector2(150, 0))
	curve.add_point(STOPS[1], Vector2(-140, -25), Vector2(140, 0))
	curve.add_point(STOPS[2], Vector2(-140, 0), Vector2(130, 0))
	curve.add_point(STOPS[3], Vector2(-130, -35), Vector2.ZERO)
	_road = curve.get_baked_points()
	queue_redraw()

func _draw() -> void:
	if _road.size() < 2: return
	# Broad lavender forms make the map feel like a page in the reference library.
	draw_polyline(_road, Color("eedfeb"), 155, true)
	for at in [STOPS[0], STOPS[3]]: draw_circle(at, 77.5, Color("eedfeb"))
	draw_polyline(_road, UiTheme.INK, 74, true)
	draw_polyline(_road, Color("cbb9df"), 66, true)
	for i in range(0, _road.size() - 2, 8):
		draw_line(_road[i], _road[mini(i + 3, _road.size() - 1)], Color("8c75a8"), 3, true)
	# A little pair of scissors and a comb echo the poster's margin drawings.
	var pale := Color("d5bcd6")
	for at in [Vector2(112, 178), Vector2(131, 192)]: draw_arc(at, 10, 0, TAU, 20, pale, 4, true)
	draw_line(Vector2(118, 185), Vector2(155, 218), pale, 4, true)
	draw_line(Vector2(137, 197), Vector2(148, 160), pale, 4, true)
	for i in 8: draw_line(Vector2(1114 + i * 7, 485 + i * 3), Vector2(1104 + i * 7, 511 + i * 3), pale, 4, true)
	draw_line(Vector2(1114, 485), Vector2(1163, 506), pale, 7, true)
	for i in STOPS.size():
		if i < unlocked.size() and not unlocked[i]: _lock(STOPS[i] + Vector2(65, -35))

func _lock(at: Vector2) -> void:
	var style := UiTheme.card(Color("dccbe6"), UiTheme.INK, 3, 7, 0)
	draw_arc(at + Vector2(0, -5), 9, PI, TAU, 20, UiTheme.INK, 4, true)
	draw_style_box(style, Rect2(at + Vector2(-12, -4), Vector2(24, 26)))
	draw_circle(at + Vector2(0, 6), 3, UiTheme.INK)
	draw_line(at + Vector2(0, 8), at + Vector2(0, 14), UiTheme.INK, 3, true)
