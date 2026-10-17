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


const ART := "res://assets/art/props/prop_door.png"


func _draw() -> void:
	var ink := Color("2b2140")
	if is_open:
		draw_rect(Rect2(Vector2.ZERO, size), Color(ink, 0.25), false, 2.0)
		return
	draw_style_box(PropArt.nine_slice(ART, 8.0), Rect2(Vector2.ZERO, size))
	var window := Vector2(size.x / 2.0, minf(24.0, size.y / 4.0))
	var r := minf(size.x / 2.0 - 5.0, 9.0)
	draw_circle(window, r + 2.0, ink)
	draw_circle(window, r, Color("bfe3ef"))
	var plate := Rect2(Vector2(3, size.y * 0.45), Vector2(size.x - 6, 11))
	draw_rect(plate.grow(1.5), ink)
	draw_rect(plate, Color("f4e9d8"))
	draw_string(ThemeDB.fallback_font, plate.position + Vector2(0, 9), "STAFF", HORIZONTAL_ALIGNMENT_CENTER, plate.size.x, 7, Color("4a3426"))
	# One gold pip per bell still needed.
	for i in maxi(locks, 1):
		var pip := Vector2(size.x / 2.0, size.y * 0.62 + i * 12)
		draw_circle(pip, 5.5, ink)
		draw_circle(pip, 4.0, Color("f1c40f"))
