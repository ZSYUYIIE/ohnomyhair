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


const ART := preload("res://assets/art/enemies/enemy_dispenser.png")


func _draw() -> void:
	var jammed := _jam > 0.0
	# The art's nozzle faces right: mirror it for left, turn it for up/down.
	if absf(direction.x) >= absf(direction.y):
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(signf(direction.x), 1.0))
	else:
		draw_set_transform(Vector2.ZERO, direction.angle())
	draw_texture(ART, Vector2(-18, -18), Color(0.78, 0.78, 0.84) if jammed else Color.WHITE)
	draw_set_transform(Vector2.ZERO)
	# Warning light: on for the last 0.4 s before a shot.
	var warn := not jammed and _timer < 0.4
	draw_circle(Vector2(0, -22), 5.0, Color("2b2140"))
	draw_circle(Vector2(0, -22), 3.6, Color("ff3b30") if warn else Color("5b2a2a"))
	if jammed and int(_jam * 6.0) % 2 == 0:
		draw_circle(Vector2(-4, -30), 6.0, Color(0.8, 0.8, 0.8, 0.7))
