@tool
class_name HotIron
extends Hazard
## A hair straightener lying open on the floor. It heats up on a timer: cold (steel
## plates), then a warning (plates glow orange, a "!" pops up) for `warn_time`, then
## red-hot for `on_time`. Touching it hot costs one heart and throws you off it - it
## burns, it doesn't kill (the player's hit invulnerability stops it hitting every frame).
## `active` false = unplugged: stays cold (a wave arena plugs it in later).

@export var off_time := 1.6
@export var warn_time := 0.5
@export var on_time := 1.0
@export var phase := 0.0
@export var active := true:
	set(value):
		active = value
		_t = 0.0
		queue_redraw()

const ART := preload("res://assets/art/props/prop_iron.png")  # cold | warming | hot, 64x32 each
const FRAME := Vector2(64, 32)

var _t := 0.0


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if active:
		_t = fmod(_t + delta, off_time + on_time)
	queue_redraw()


func is_active() -> bool:
	return active and _cycle_time() >= off_time


func _is_warning() -> bool:
	var t := _cycle_time()
	return active and t >= off_time - warn_time and t < off_time


func _cycle_time() -> float:
	return fmod(_t + phase, off_time + on_time)


func _touch(body: Node) -> void:
	if body is Player:
		Sound.play("iron_hiss")
		var away := signf(body.global_position.x - (global_position.x + size.x / 2.0))
		body.take_hit(1, 0.0, Vector2((away if away != 0.0 else 1.0) * 380.0, -420.0))


func _draw() -> void:
	var hot := is_active()
	var frame := 2 if hot else 1 if _is_warning() else 0
	var art_rect := Rect2(0, size.y - FRAME.y, size.x, FRAME.y)
	if hot:
		# Red-hot glow on the floor around it, pulsing.
		var pulse := 0.5 + 0.5 * sin(_t * 14.0)
		draw_rect(art_rect.grow_individual(10, 8, 10, 0), Color(1.0, 0.35, 0.15, 0.18 + 0.12 * pulse))
	draw_texture_rect_region(ART, art_rect, Rect2(frame * FRAME.x, 0, FRAME.x, FRAME.y))
	var top := size.y - FRAME.y
	if hot:
		# Heat shimmer rising off the plates.
		var x := 8.0
		while x < size.x - 4.0:
			var sway := sin(_t * 9.0 + x) * 3.0
			draw_line(Vector2(x, top + 6), Vector2(x + sway, top - 10), Color(1.0, 0.55, 0.2, 0.85), 2.5)
			draw_line(Vector2(x + sway, top - 10), Vector2(x - sway, top - 26), Color(1.0, 0.75, 0.3, 0.5), 2.0)
			x += 12.0
	elif _is_warning():
		# "!" bubble: about to heat up.
		var c := Vector2(size.x / 2.0, top - 18)
		draw_circle(c, 11.0, Color("2b2140"))
		draw_circle(c, 8.5, Color("f1c40f"))
		draw_rect(Rect2(c.x - 1.5, c.y - 5.5, 3, 7), Color("2b2140"))
		draw_rect(Rect2(c.x - 1.5, c.y + 3, 3, 3), Color("2b2140"))
