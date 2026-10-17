class_name ScissorTurret
extends StaticBody2D
## Fixed turret that fires scissors on a timer. A parried scissor jams it (take_hit stun).

@export var interval := 2.5
@export var direction := Vector2.LEFT
@export var first_shot_delay := 1.0

var _timer := 0.0
var _jam := 0.0


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = Layers.ENEMIES
	collision_mask = 0
	Player._add_rect_shape(self, Vector2(14, 14), Vector2.ZERO)
	_timer = first_shot_delay


func _physics_process(delta: float) -> void:
	if _jam > 0.0:
		_jam -= delta
		queue_redraw()
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = interval
		fire()


func fire() -> void:
	var scissor := Scissor.new()
	scissor.direction = direction
	scissor.position = position + direction * 12.0
	get_parent().add_child.call_deferred(scissor)


## Turrets can't be destroyed; any hit just jams them for stun_time seconds.
func take_hit(_damage: int, stun_time: float = 0.0, _knockback := Vector2.ZERO) -> void:
	if stun_time > _jam:
		_jam = stun_time
		_timer = interval
	queue_redraw()


func _draw() -> void:
	var body := Color("6b6b7b") if _jam > 0.0 else Color("c0392b")
	draw_rect(Rect2(-7, -7, 14, 14), body)
	draw_rect(Rect2(Vector2(-7, -2) + direction * 6.0, Vector2(6, 4)), Color("2c2c34"))
	if _jam > 0.0 and int(_jam * 6.0) % 2 == 0:
		draw_circle(Vector2(-2, -11), 3.0, Color(0.8, 0.8, 0.8, 0.7))
