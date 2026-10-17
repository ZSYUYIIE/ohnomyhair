class_name ClipperBot
extends CharacterBody2D
## Melee enemy: PATROL -> STUNNED -> DEAD (PLAN.md 1.3). Touching it hurts unless it's stunned.

const SIZE := Vector2(14, 12)

@export var speed := 50.0
@export var patrol_range := 48.0
@export var hp := 2

var direction := 1.0
var stun := 0.0
var _start_x := 0.0


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = Layers.ENEMIES
	collision_mask = Layers.WORLD
	Player._add_rect_shape(self, SIZE, Vector2(0, -SIZE.y / 2))
	_start_x = global_position.x


func _physics_process(delta: float) -> void:
	velocity.y += 900.0 * delta
	if stun > 0.0:
		stun -= delta
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
	else:
		if global_position.x > _start_x + patrol_range:
			direction = -1.0
		elif global_position.x < _start_x - patrol_range:
			direction = 1.0
		velocity.x = direction * speed
		_hurt_touching_players()
	move_and_slide()
	if is_on_wall() and stun <= 0.0:
		direction *= -1.0
	queue_redraw()


func _hurt_touching_players() -> void:
	var me := Rect2(global_position + Vector2(-SIZE.x / 2, -SIZE.y), SIZE)
	for p in get_tree().get_nodes_in_group("players"):
		var them := Rect2(p.global_position + Vector2(-Player.BODY_SIZE.x / 2, -Player.BODY_SIZE.y), Player.BODY_SIZE)
		if me.intersects(them):
			p.take_hit(1, 0.0, Vector2(signf(p.global_position.x - global_position.x) * 160.0, -140.0))


func take_hit(damage: int, stun_time: float = 0.0, knockback := Vector2.ZERO) -> void:
	hp -= damage
	stun = maxf(stun, stun_time)
	if knockback != Vector2.ZERO:
		velocity = knockback
	if hp <= 0:
		queue_free()


func _draw() -> void:
	var body := Color("7f8c8d") if stun > 0.0 else Color("d35400")
	draw_rect(Rect2(Vector2(-SIZE.x / 2, -SIZE.y), SIZE), body)
	draw_rect(Rect2(Vector2(SIZE.x / 2 * direction - 1.0, -9), Vector2(2, 6)), Color("ecf0f1"))
	if stun > 0.0:
		draw_circle(Vector2(0, -16), 2.0, Color.YELLOW)
