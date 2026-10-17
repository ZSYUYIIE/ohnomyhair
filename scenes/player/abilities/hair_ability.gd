class_name HairAbility
extends Node2D
## Base class for a haircut's skill + attack. Lives under the player's Visual node,
## so it flips with facing and draws the hair itself. Swapping hairstyles = swapping
## this node (Player.set_hair).

var player: Player
var body_color := Color.WHITE
var display_name := ""


## Called every physics tick before the player moves. Read input via player.pressed()/held().
func tick(_delta: float) -> void:
	pass


## True while the ability fully controls velocity (e.g. a dash); normal movement is skipped.
func is_driving() -> bool:
	return false


## Called after move_and_slide(); slide collisions are available here.
func after_move() -> void:
	pass


## Clear any in-progress state (respawn, hair swap).
func reset() -> void:
	pass


## Hits everything in the player's hit box once per swing (`struck` remembers who).
func strike(struck: Array[Node], damage: int, stun: float, knockback: Vector2) -> void:
	for body in player.hit_box.get_overlapping_bodies():
		if body.has_method("take_hit") and body not in struck:
			struck.append(body)
			body.take_hit(damage, stun, Vector2(knockback.x * player.facing, knockback.y))
