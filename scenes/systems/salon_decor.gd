@tool
class_name SalonDecor
extends Node2D
## Background dressing for one room: striped wallpaper, gilt mirrors with lamps, and
## barber poles between them. Purely visual and faded, drawn behind the tiles, so it
## never competes with gameplay objects. `layout_seed` picks the arrangement.

@export var layout_seed := 0:
	set(value):
		layout_seed = value
		queue_redraw()
@export var size := Vector2(1280, 720)
@export var wall_color := Color("efe0f0"):
	set(value):
		wall_color = value
		queue_redraw()


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = layout_seed
	var x := 0.0
	while x < size.x:
		draw_rect(Rect2(x, 0, 24, size.y), wall_color.darkened(0.035))
		x += 48.0

	var mirrors := rng.randi_range(3, 4)
	var centers: Array[float] = []
	for i in mirrors:
		var cx := size.x * (i + 0.5) / mirrors + rng.randf_range(-50.0, 50.0)
		centers.append(cx)
		_mirror(Rect2(cx - 48, 120 + rng.randf_range(-10.0, 20.0), 96, 136))
		_lamp(cx)
	for i in mirrors - 1:
		_barber_pole(Vector2((centers[i] + centers[i + 1]) / 2.0 - 10.0, 150))


func _mirror(r: Rect2) -> void:
	var gilt := Color("b08d57", 0.5)
	draw_rect(r.grow(8), gilt)
	draw_rect(r, Color("dceff5", 0.55))
	draw_line(r.position + Vector2(18, r.size.y - 26), r.position + Vector2(r.size.x - 30, 22), Color(1, 1, 1, 0.5), 6.0)
	draw_line(r.position + Vector2(38, r.size.y - 18), r.position + Vector2(r.size.x - 18, 40), Color(1, 1, 1, 0.3), 3.0)


func _lamp(cx: float) -> void:
	draw_line(Vector2(cx, 32), Vector2(cx, 72), Color(0.3, 0.3, 0.3, 0.4), 2.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 18, 88), Vector2(cx + 18, 88), Vector2(cx + 8, 72), Vector2(cx - 8, 72),
	]), Color("e8c56a", 0.55))


## Red, white and blue spiral, approximated with slanted stripes inside a glass tube.
func _barber_pole(top_left: Vector2) -> void:
	var w := 20.0
	var h := 110.0
	draw_rect(Rect2(top_left, Vector2(w, h)), Color(1, 1, 1, 0.5))
	var y := 6.0
	var i := 0
	while y < h:
		var c := Color("d63031", 0.55) if i % 2 == 0 else Color("2d6cdf", 0.55)
		draw_line(top_left + Vector2(0, y + 10), top_left + Vector2(w, y), c, 5.0)
		y += 14.0
		i += 1
	draw_rect(Rect2(top_left + Vector2(-3, -8), Vector2(w + 6, 8)), Color(0.75, 0.77, 0.8, 0.6))
	draw_rect(Rect2(top_left + Vector2(-3, h), Vector2(w + 6, 8)), Color(0.75, 0.77, 0.8, 0.6))
