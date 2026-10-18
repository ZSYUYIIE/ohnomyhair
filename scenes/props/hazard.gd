@tool
class_name Hazard
extends Area2D
## Kills any player overlapping it while active (hair-dye basins, hot irons).
## Position is the top-left corner.

@export var size := Vector2(128, 64):
	set(value):
		size = value
		queue_redraw()
@export var color := Color("8e44ad")


func _ready() -> void:
	queue_redraw()
	if Engine.is_editor_hint():
		return
	var rect := RectangleShape2D.new()
	rect.size = size
	$Shape.shape = rect
	$Shape.position = size / 2.0


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or not is_active():
		return
	var me := Rect2(global_position, size)
	for body in get_overlapping_bodies():
		# The overlap list can lag a physics step behind a teleport: a player who just
		# respawned elsewhere would die twice. Trust only a real rect overlap.
		if body is Player and not me.intersects(Rect2(body.global_position - Player.HALF_SIZE, Player.HALF_SIZE * 2.0)):
			continue
		_touch(body)


## What touching it does: hair dye is deadly. Hazards that only hurt override this.
func _touch(body: Node) -> void:
	if body.has_method("die"):
		if body is Player and body.alive:
			Sound.play("splash")
		body.die()


func is_active() -> bool:
	return true


func _draw() -> void:
	# A salon wash basin full of hair dye: dye fills the area, white rims on both sides.
	draw_style_box(PropArt.nine_slice("res://assets/art/props/prop_dye.png", 16.0), Rect2(Vector2.ZERO, size))
	for x in [-4.0, size.x - 4.0]:
		draw_rect(Rect2(x, -6, 8, size.y + 6), Color("f4f1ec"))
		draw_rect(Rect2(x, -6, 8, size.y + 6), Color("2b2140"), false, 2.0)
