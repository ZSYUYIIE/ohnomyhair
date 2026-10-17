class_name Door
extends StaticBody2D
## Solid until open() has been called `locks` times (one per switch wired to it).
## Origin is the top-left corner.

@export var size := Vector2(32, 160)
@export var locks := 1

var is_open := false
var _shape: CollisionShape2D


func _ready() -> void:
	collision_layer = Layers.WORLD
	collision_mask = 0
	_shape = Player.add_rect_shape(self, size, size / 2)


func open() -> void:
	locks -= 1
	queue_redraw()
	if locks > 0 or is_open:
		return
	is_open = true
	_shape.set_deferred("disabled", true)
	queue_redraw()


func _draw() -> void:
	var wood := Color("8e6e53")
	if is_open:
		draw_rect(Rect2(Vector2.ZERO, size), wood, false, 2.0)
		return
	draw_rect(Rect2(Vector2.ZERO, size), wood)
	draw_rect(Rect2(Vector2(3, 3), size - Vector2(6, 6)), wood.darkened(0.2), false, 2.0)
	draw_circle(Vector2(size.x / 2.0, minf(24.0, size.y / 4.0)), minf(size.x / 2.0 - 4.0, 9.0), Color("bfe3ef"))
	draw_rect(Rect2(Vector2(2, size.y * 0.45), Vector2(size.x - 4, 10)), Color("f4e9d8"))
	draw_string(ThemeDB.fallback_font, Vector2(3, size.y * 0.45 + 9), "STAFF", HORIZONTAL_ALIGNMENT_LEFT, size.x - 6, 9, Color("4a3426"))
	# One gold pip per bell still needed.
	for i in maxi(locks, 1):
		draw_circle(Vector2(size.x / 2.0, size.y * 0.62 + i * 12), 4.0, Color("f1c40f"))
