class_name Door
extends StaticBody2D
## Solid until open() is called. Origin is the top-left corner.

@export var size := Vector2(16, 80)

var is_open := false
var _shape: CollisionShape2D


func _ready() -> void:
	collision_layer = Layers.WORLD
	collision_mask = 0
	_shape = Player._add_rect_shape(self, size, size / 2)


func open() -> void:
	is_open = true
	_shape.set_deferred("disabled", true)
	queue_redraw()


func _draw() -> void:
	if is_open:
		draw_rect(Rect2(Vector2.ZERO, size), Color("8e6e53"), false, 1.0)
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color("8e6e53"))
		draw_rect(Rect2(Vector2(size.x - 6, size.y / 2), Vector2(3, 3)), Color("f1c40f"))
