class_name ClipperBot
extends CharacterBody2D
## Melee enemy: PATROL -> STUNNED -> DEAD. Touching it hurts unless it's stunned.
## Origin is at the feet.

const SIZE := Vector2(28, 24)

@export var speed := 100.0
@export var patrol_range := 96.0
@export var hp := 2

var direction := 1.0
var stun := 0.0
var _start_x := 0.0


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = Layers.ENEMIES
	collision_mask = Layers.WORLD
	Player.add_rect_shape(self, SIZE, Vector2(0, -SIZE.y / 2))
	_start_x = global_position.x


func _physics_process(delta: float) -> void:
	velocity.y += 1800.0 * delta
	if stun > 0.0:
		stun -= delta
		velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
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
	for p: Player in get_tree().get_nodes_in_group("players"):
		var them := Rect2(p.global_position - Player.HALF_SIZE, Player.HALF_SIZE * 2.0)
		if p.alive and me.intersects(them):
			p.take_hit(1, 0.0, Vector2(signf(p.global_position.x - global_position.x) * 320.0, -280.0))


func take_hit(damage: int, stun_time: float = 0.0, knockback := Vector2.ZERO) -> void:
	hp -= damage
	stun = maxf(stun, stun_time)
	if knockback != Vector2.ZERO:
		velocity = knockback
	if hp <= 0:
		queue_free()


func _draw() -> void:
	# An electric hair clipper on the loose.
	var stunned := stun > 0.0
	var body := Color("7f8c8d") if stunned else Color("34495e")
	var front := SIZE.x / 2.0 * direction
	draw_rect(Rect2(Vector2(-SIZE.x / 2, -SIZE.y + 4), Vector2(SIZE.x, SIZE.y - 4)), body)
	draw_rect(Rect2(Vector2(-SIZE.x / 2, -SIZE.y), Vector2(SIZE.x, 6)), body.lightened(0.2))
	for i in 5:
		var y := -SIZE.y + 3.0 + i * 4.5
		draw_line(Vector2(front, y), Vector2(front + 6.0 * direction, y), Color("ecf0f1"), 2.0)
	draw_circle(Vector2(-front * 0.4, -SIZE.y + 10), 2.5, Color("555555") if stunned else Color("2ecc71"))
	draw_line(Vector2(-front, -6), Vector2(-front - 10.0 * direction, -2), Color("222222"), 2.0)
	if stunned:
		draw_circle(Vector2(0, -32), 4.0, Color.YELLOW)
