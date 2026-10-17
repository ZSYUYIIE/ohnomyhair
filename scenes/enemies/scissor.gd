class_name Scissor
extends Area2D
## Projectile from turrets and the barber bot. Hurts players; after a parry it switches
## to player_attack and can hit enemies, deflectors and switches.

const SPEED := 240.0
const DEFLECT_SPEED_MULTIPLIER := 1.5
const DAMAGE := 1

var direction := Vector2.LEFT
var speed := SPEED
var deflected := false


func _ready() -> void:
	add_to_group("scissors")
	collision_layer = Layers.ENEMY_ATTACK
	collision_mask = Layers.WORLD | Layers.PLAYERS
	Player.add_rect_shape(self, Vector2(20, 8), Vector2.ZERO)
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func deflect() -> void:
	deflected = true
	direction = -direction
	speed *= DEFLECT_SPEED_MULTIPLIER
	rotation = direction.angle()
	collision_layer = Layers.PLAYER_ATTACK
	collision_mask = Layers.WORLD | Layers.ENEMIES | Layers.INTERACTABLES
	queue_redraw()


func redirect(new_direction: Vector2, at: Vector2) -> void:
	direction = new_direction
	global_position = at
	rotation = direction.angle()


func _on_body_entered(body: Node) -> void:
	if body.has_method("take_hit"):
		if deflected:
			body.take_hit(DAMAGE, 3.0)
		else:
			body.take_hit(DAMAGE, 0.0, Vector2(signf(direction.x) * 280.0, -240.0))
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if deflected and area.has_method("on_scissor"):
		area.on_scissor(self)


func _draw() -> void:
	var c := Color("5ce1e6") if deflected else Color("ff5a5a")
	draw_line(Vector2(-10, -4), Vector2(10, 4), c, 4.0)
	draw_line(Vector2(-10, 4), Vector2(10, -4), c, 4.0)
	draw_circle(Vector2(-10, -4), 3.0, c)
	draw_circle(Vector2(-10, 4), 3.0, c)
