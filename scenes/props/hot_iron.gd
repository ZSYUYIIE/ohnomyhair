@tool
class_name HotIron
extends Hazard
## A hair straightener lying open on the floor. It heats up on a timer: the plates
## glow orange for `warn_time` (read the rhythm), then turn red-hot and burn for `on_time`.

@export var off_time := 1.6
@export var warn_time := 0.5
@export var on_time := 1.0
@export var phase := 0.0

const ART := preload("res://assets/art/props/prop_iron.png")

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
	# Frames: cold | red-hot. While warning it flickers between the two.
	var hot := is_active() or (_is_warning() and fmod(_t, 0.2) < 0.1)
	draw_texture_rect_region(ART, Rect2(0, size.y - 24, size.x, 24), Rect2(64 if hot else 0, 0, 64, 24))
	if is_active():
		# Steam wisps rising off the plates.
		var h := size.y
		var x := 10.0
		while x < size.x - 6.0:
			var sway := sin(_t * 9.0 + x) * 3.0
			draw_line(Vector2(x, h - 16), Vector2(x + sway, h - 30), Color(1, 1, 1, 0.75), 2.0)
			draw_line(Vector2(x + sway, h - 30), Vector2(x - sway, h - 42), Color(1, 1, 1, 0.45), 2.0)
			x += 14.0
