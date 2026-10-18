@tool
class_name HairSwapChair
extends Area2D
## The barber's chair ("Something's Off"): the first time a player walks into its zone,
## both friends' haircuts are swapped - and so are their powers.
## Position is the top-left corner of the trigger zone; the chair sits at its bottom center.

signal swapped

@export var size := Vector2(256, 128):
	set(value):
		size = value
		queue_redraw()

var used := false


func _ready() -> void:
	queue_redraw()
	if Engine.is_editor_hint():
		return
	var rect := RectangleShape2D.new()
	rect.size = size
	$Shape.shape = rect
	$Shape.position = size / 2.0
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if used or not body is Player:
		return
	used = true
	_swap.call_deferred()


func _swap() -> void:
	Sound.play("swap", 0.0)
	var players := get_tree().get_nodes_in_group("players")
	for p: Player in players:
		p.drop()
	if players.size() >= 2:
		var first_hair: Player.Hair = players[0].hair
		players[0].set_hair(players[1].hair)
		players[1].set_hair(first_hair)
	var level := owner as Level
	if level:
		level.flash_screen(1.0, Color("ff5fa2"))
		level.show_banner("Haircuts swapped! Check your skills in the HUD.", 2.0)
	swapped.emit()
	queue_redraw()


const ART := preload("res://assets/art/props/chair_flat.svg")
const DRAW_SIZE := Vector2(64, 75)


func _draw() -> void:
	# The shared coral chair stands at the zone's bottom center; used leather darkens.
	var base := Vector2(size.x / 2.0, size.y)
	draw_texture_rect(ART, Rect2(base - Vector2(DRAW_SIZE.x / 2.0, DRAW_SIZE.y), DRAW_SIZE), false, Color(0.72, 0.72, 0.78) if used else Color.WHITE)
	if used:
		draw_string(ThemeDB.fallback_font, base + Vector2(-22, -81), "snip!", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ff5fa2"))
