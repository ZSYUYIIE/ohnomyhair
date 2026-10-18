class_name Scissor
extends Area2D
## Projectile from turrets and the barber bot. Hurts players; after a parry it switches
## to player_attack and can hit enemies and service bells.

const SPEED := 240.0
const DEFLECT_SPEED_MULTIPLIER := 1.5
const DAMAGE := 1

var direction := Vector2.LEFT
var speed := SPEED
var deflected := false
## Tossed up by twin-tails after a Hair Catch: flies straight up, twice as fast.
var golden := false
## Twin-tails holding it in her pigtails (Hair Catch), or null.
var holder: Player = null
## Only Tony's scissors restyle a player, and only after an unblocked damaging hit.
var restyles := false


func _ready() -> void:
	add_to_group("scissors")
	collision_layer = Layers.ENEMY_ATTACK
	collision_mask = Layers.WORLD | Layers.PLAYERS
	Player.add_rect_shape(self, Vector2(20, 8), Vector2.ZERO)
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	if holder:
		if not is_instance_valid(holder) or not holder.alive:
			queue_free()
			return
		global_position = holder.global_position + Vector2(0, -Player.HALF_SIZE.y - 26)
		rotation += delta * 18.0
		return
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


## Combo "Hair Catch": twin-tails' open pigtails grab a parried scissor and hold it.
## Held scissors don't hit anything until tossed.
func catch_by(p: Player) -> void:
	holder = p
	set_deferred("monitoring", false)


## Twin-tails lets go: the scissor shoots straight up from `at_x`, golden.
func toss(at_x: float) -> void:
	holder = null
	set_deferred("monitoring", true)
	golden = true
	direction = Vector2.UP
	speed = SPEED * 2.0
	global_position.x = at_x
	rotation = direction.angle()
	queue_redraw()


func return_from_afro(facing: float) -> void:
	holder = null
	golden = true
	deflected = true
	restyles = false
	direction = Vector2(facing, 0)
	speed = SPEED * 2
	rotation = direction.angle()
	global_position += Vector2(facing * 42, 0)
	set_deferred("monitoring", true)
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if body.has_method("take_hit"):
		if golden:
			body.take_hit(DAMAGE * 2, 6.0)
		elif deflected:
			body.take_hit(DAMAGE, 3.0)
		else:
			var hp_before: int = body.hp if body is Player else 0
			body.take_hit(DAMAGE, 0.0, Vector2(signf(direction.x) * 280.0, -240.0))
			if restyles and body is Player and body.alive and body.hp < hp_before:
				body.restyle_next.call_deferred()
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if deflected and area.has_method("on_scissor"):
		area.on_scissor(self)


const ART := preload("res://assets/art/enemies/enemy_scissor.png")


func _draw() -> void:
	# Frames: enemy (red) | parried (cyan) | golden. The node's rotation points it.
	var frame := 2 if golden else 1 if deflected else 0
	draw_texture_rect_region(ART, Rect2(-14, -8, 28, 16), Rect2(frame * 28, 0, 28, 16))
