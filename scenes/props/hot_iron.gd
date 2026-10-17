@tool
class_name HotIron
extends Hazard
## A hair straightener lying open on the floor. It heats up on a timer: the plates
## glow orange for `warn_time` (read the rhythm), then turn red-hot and burn for `on_time`.

@export var off_time := 1.6
@export var warn_time := 0.5
@export var on_time := 1.0
@export var phase := 0.0

var _t := 0.0


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t = fmod(_t + delta, off_time + on_time)
	queue_redraw()


func is_active() -> bool:
	return _cycle_time() >= off_time


func _is_warning() -> bool:
	var t := _cycle_time()
	return t >= off_time - warn_time and t < off_time


func _cycle_time() -> float:
	return fmod(_t + phase, off_time + on_time)


func _draw() -> void:
	var chrome := Color("c8ccd2")
	var plate := Color("8a9099")
	if is_active():
		plate = Color("ff4b2b")
	elif _is_warning():
		plate = Color("ff9f43") if fmod(_t, 0.2) < 0.1 else Color("b37a4c")
	# Two long plates, hinged at the left end; a cord trails off the right.
	var h := size.y
	draw_rect(Rect2(0, h - 8, size.x, 8), Color("2d2d34"))
	draw_rect(Rect2(4, h - 14, size.x - 8, 6), plate)
	draw_rect(Rect2(4, h - 15, size.x - 8, 2), chrome)
	draw_circle(Vector2(6, h - 8), 5.0, Color("2d2d34"))
	draw_line(Vector2(size.x, h - 4), Vector2(size.x + 10, h - 1), Color("2d2d34"), 3.0)
	if is_active():
		# Steam wisps rising off the plates.
		var x := 10.0
		while x < size.x - 6.0:
			var sway := sin(_t * 9.0 + x) * 3.0
			draw_line(Vector2(x, h - 16), Vector2(x + sway, h - 30), Color(1, 1, 1, 0.7), 2.0)
			draw_line(Vector2(x + sway, h - 30), Vector2(x - sway, h - 42), Color(1, 1, 1, 0.4), 2.0)
			x += 14.0
