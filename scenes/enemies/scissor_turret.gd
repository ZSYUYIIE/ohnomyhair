class_name ScissorTurret
extends StaticBody2D
## Wall-mounted scissor dispenser: fires scissors on a timer (a red light blinks just before). A parried scissor jams it (take_hit stun).

@export var interval := 2.5
@export var direction := Vector2.LEFT
@export var first_shot_delay := 1.0

var _timer := 0.0
var _jam := 0.0


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = Layers.ENEMIES
	collision_mask = 0
	Player.add_rect_shape(self, Vector2(28, 28), Vector2.ZERO)
	_timer = first_shot_delay


func _physics_process(delta: float) -> void:
	if _jam > 0.0:
		_jam -= delta
		queue_redraw()
		return
	_timer -= delta
	if _timer < 0.45:
		queue_redraw()
	if _timer <= 0.0:
		_timer = interval
		fire()


func fire() -> void:
	var scissor := Scissor.new()
	scissor.direction = direction
	scissor.position = position + direction * 24.0
	get_parent().add_child.call_deferred(scissor)


## Turrets can't be destroyed; any hit just jams them for stun_time seconds.
func take_hit(_damage: int, stun_time: float = 0.0, _knockback := Vector2.ZERO) -> void:
	if stun_time > _jam:
		_jam = stun_time
		_timer = interval
	queue_redraw()


func _draw() -> void:
	var jammed := _jam > 0.0
	var body := Color("9aa0a6") if jammed else Color("c8ccd2")
	draw_rect(Rect2(-14, -14, 28, 28), body)
	draw_rect(Rect2(-14, -14, 28, 28), body.darkened(0.35), false, 2.0)
	draw_rect(Rect2(Vector2(-14, -4) + direction * 12.0, Vector2(12, 8)), Color("2c2c34"))
	# Little scissors logo.
	draw_circle(Vector2(-4, 6), 3.0, Color("c0392b"))
	draw_circle(Vector2(4, 6), 3.0, Color("c0392b"))
	draw_line(Vector2(-2, 4), Vector2(6, -8), Color("5b6068"), 2.0)
	draw_line(Vector2(2, 4), Vector2(-6, -8), Color("5b6068"), 2.0)
	# Warning light: on for the last 0.4 s before a shot.
	var warn := not jammed and _timer < 0.4
	draw_circle(Vector2(0, -20), 4.0, Color("ff3b30") if warn else Color("5b2a2a"))
	if jammed and int(_jam * 6.0) % 2 == 0:
		draw_circle(Vector2(-4, -26), 6.0, Color(0.8, 0.8, 0.8, 0.7))
