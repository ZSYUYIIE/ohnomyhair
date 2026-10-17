@tool
class_name PeriodicSpikes
extends Hazard
## Comb teeth that pop out on a timer. They flash for `warn_time` before
## rising so players can read the rhythm.

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
	var tooth := 16.0
	var height := size.y if is_active() else 6.0
	var c := Color("e74c3c") if is_active() else Color("f1c40f") if _is_warning() and fmod(_t, 0.2) < 0.1 else Color("7f8c8d")
	var x := 0.0
	while x < size.x:
		draw_colored_polygon(PackedVector2Array([Vector2(x, size.y), Vector2(x + tooth / 2.0, size.y - height), Vector2(x + tooth, size.y)]), c)
		x += tooth
