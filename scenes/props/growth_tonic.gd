class_name GrowthTonic
extends Area2D
## Hair-growth tonic bottle: grows back one notch of hair (1 HP). A friend at full hair
## leaves it for the other. Comes back when the room restarts. Position is its center.

var _t := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.PLAYERS
	monitorable = false
	Player.add_rect_shape(self, Vector2(24, 32), Vector2.ZERO)


func _physics_process(delta: float) -> void:
	_t += delta
	for body in get_overlapping_bodies():
		if body is Player and body.heal(1):
			queue_free()
			return
	queue_redraw()


func _draw() -> void:
	var bob := sin(_t * 3.0) * 3.0
	var glass := Color("6fcf97")
	draw_rect(Rect2(-9, -10 + bob, 18, 22), glass)
	draw_rect(Rect2(-4, -16 + bob, 8, 6), glass.darkened(0.2))
	draw_rect(Rect2(-5, -20 + bob, 10, 4), Color("c0392b"))
	draw_rect(Rect2(-7, -4 + bob, 14, 8), Color("fffaf0"))
	draw_line(Vector2(-4, 0 + bob), Vector2(4, 0 + bob), Color("2e8b57"), 2.0)
	if int(_t * 4.0) % 2 == 0:
		draw_circle(Vector2(11, -14 + bob), 2.0, Color(1, 1, 1, 0.9))
