class_name HairAbility
extends Node
## A hairstyle's skill + attack. Swapping hairstyles = swapping this node (PLAN.md 1.5).

var player: Player


func setup(p: Player) -> void:
	player = p


## Called every physics frame after the player's own movement, before the fall-speed clamp.
func tick(_delta: float) -> void:
	pass


## Called from the player's _draw so hair can be drawn on top of the body.
func draw_hair(_canvas: CanvasItem) -> void:
	pass
