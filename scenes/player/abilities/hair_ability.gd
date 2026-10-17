class_name HairAbility
extends Node2D
## Base class for a haircut's powers. Lives under the player's Visual node,
## so it flips with facing and can draw the hair itself.

var player: Player
var body_color := Color.WHITE


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
