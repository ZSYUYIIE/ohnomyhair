class_name HairAbility
extends Node2D
## Base class for a haircut's skill + attack. Lives under the player's Visual node, so it
## flips with facing. The hair is drawn in the character's sprite frames (body and hair
## together), so swapping hairstyles = swapping this node and its `frames` (Player.set_hair).

var player: Player
var body_color := Color.WHITE
var display_name := ""
## Sprite frames for a friend wearing this haircut: idle, run, jump, fall, hang + skill moves.
var frames: SpriteFrames


## Called every physics tick before the player moves. Read input via player.pressed()/held().
func tick(_delta: float) -> void:
	pass


## Attack-only tick (no skill, no movement).
func tick_attack(_delta: float) -> void:
	pass


## Called instead of tick() while dangling from a friend's hair. Default: attack only.
## Abilities can override it for carried combos (pompadour's sling dash).
func tick_carried(delta: float) -> void:
	tick_attack(delta)


## True while gliding (hair dryers only lift gliders).
func is_gliding() -> bool:
	return false


## Animation the haircut wants right now (skill or attack pose), or &"" to let the player
## pick one from movement.
func anim() -> StringName:
	return &""


## Source-resolution atlas frames can retain their full silhouette without clipping.
func frame_scale(_animation: StringName) -> float:
	return 1.0


func frame_material(_animation: StringName) -> Material:
	return null


## True while the ability fully controls velocity (e.g. a dash); normal movement is skipped.
func is_driving() -> bool:
	return false


## Called after move_and_slide(); slide collisions are available here.
func after_move() -> void:
	pass


## Clear any in-progress state (respawn, hair swap).
func reset() -> void:
	pass


## Defensive abilities may absorb a hit before HP is reduced. Lethal hazards still kill.
func block_hit() -> bool:
	return false


func move_multiplier() -> float:
	return 1.0


## Hits everything in the player's hit box once per swing (`struck` remembers who).
func strike(struck: Array[Node], damage: int, stun: float, knockback: Vector2) -> void:
	for body in player.hit_box.get_overlapping_bodies():
		if body.has_method("take_hit") and body not in struck:
			struck.append(body)
			body.take_hit(damage, stun, Vector2(knockback.x * player.facing, knockback.y))
