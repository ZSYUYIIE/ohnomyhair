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
	var players := get_tree().get_nodes_in_group("players")
	for p: Player in players:
		p.drop()
	for p: Player in players:
		p.set_hair(Player.Hair.POMPADOUR if p.hair == Player.Hair.TWIN_TAILS else Player.Hair.TWIN_TAILS)
	var level := owner as Level
	if level:
		level.flash_screen(1.0, Color("ff5fa2"))
		level.show_banner("Snip snip...\nWait. What?! Your haircuts got SWAPPED!", 3.5)
	swapped.emit()
	queue_redraw()


func _draw() -> void:
	var base := Vector2(size.x / 2.0, size.y)
	var leather := Color("8e2f3c") if not used else Color("5b1f27")
	draw_rect(Rect2(base + Vector2(-6, -40), Vector2(12, 40)), Color("9aa0a6"))       # pole
	draw_rect(Rect2(base + Vector2(-40, -4), Vector2(80, 4)), Color("9aa0a6"))        # foot
	draw_rect(Rect2(base + Vector2(-36, -56), Vector2(72, 16)), leather)              # seat
	draw_rect(Rect2(base + Vector2(-36, -112), Vector2(16, 60)), leather)             # back
	draw_rect(Rect2(base + Vector2(-44, -64), Vector2(12, 8)), Color("9aa0a6"))       # armrest
	draw_rect(Rect2(base + Vector2(32, -64), Vector2(12, 8)), Color("9aa0a6"))
	if used:
		draw_string(ThemeDB.fallback_font, base + Vector2(-30, -124), "snip!", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("ff5fa2"))
