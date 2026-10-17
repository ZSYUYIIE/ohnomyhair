class_name ShowerHead
extends Area2D
## Shampoo-station shower: sprays a curtain of water on a timer and soaks anyone under it.
## Wet twin-tails can't glide, wet pompadour can't smash gel; a hair dryer dries you.
## off_time 0 = always on. Position is the top-left of the spray zone; the head hangs at its top.

@export var size := Vector2(96, 448)
@export var off_time := 1.8
@export var warn_time := 0.6
@export var on_time := 1.6
@export var phase := 0.0
@export var wet_seconds := 8.0

var _t := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.PLAYERS
	monitorable = false
	Player.add_rect_shape(self, size, size / 2.0)


func _physics_process(delta: float) -> void:
	_t += delta
	if is_active():
		for body in get_overlapping_bodies():
			if body is Player:
				body.soak(wet_seconds)
	queue_redraw()


func is_active() -> bool:
	return off_time <= 0.0 or _cycle_time() >= off_time


func _is_warning() -> bool:
	var t := _cycle_time()
	return off_time > 0.0 and t >= off_time - warn_time and t < off_time


func _cycle_time() -> float:
	return fmod(_t + phase, off_time + on_time)


func _draw() -> void:
	var cx := size.x / 2.0
	# Pipe from the ceiling and the chrome head.
	draw_rect(Rect2(cx - 3, 0, 6, 10), Color("9aa0a6"))
	draw_colored_polygon(PackedVector2Array([Vector2(cx - 26, 22), Vector2(cx + 26, 22), Vector2(cx + 12, 8), Vector2(cx - 12, 8)]), Color("c8ccd2"))
	var water := Color("4aa3df")
	if is_active():
		draw_rect(Rect2(cx - 24, 22, 48, size.y - 22), Color(water, 0.18))
		var lanes := 6
		for i in lanes:
			var x := cx - 22.0 + i * 44.0 / (lanes - 1)
			var y := fmod(_t * 520.0 + i * 37.0, 60.0)
			while y < size.y - 22.0:
				draw_line(Vector2(x, 22 + y), Vector2(x, 22 + y + 18), Color(water, 0.75), 2.0)
				y += 60.0
	elif _is_warning():
		for i in 3:
			var y := fmod(_t * 200.0 + i * 20.0, 60.0)
			draw_circle(Vector2(cx - 12.0 + i * 12.0, 26 + y), 3.0, water)
