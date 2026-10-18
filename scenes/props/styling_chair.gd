extends Area2D
## A safe co-op styling station. Down opens selection only when both friends are nearby.
const ART := preload("res://assets/art/props/prop_chair.png")
var level: Level
var _near := false

func _ready() -> void:
	collision_layer = Layers.INTERACTABLES
	collision_mask = Layers.PLAYERS
	Player.add_rect_shape(self, Vector2(120, 100), Vector2(0, -40))

func _physics_process(_delta: float) -> void:
	_near = false
	for body in get_overlapping_bodies():
		if body is Player and body.alive:
			_near = true
			if body.pressed("down") and body.is_on_floor():
				level.open_styling.call_deferred(self)
	queue_redraw()

func _draw() -> void:
	draw_texture_rect_region(ART, Rect2(-35, -75, 70, 75), Rect2(0, 0, 112, 120))
	draw_circle(Vector2(0, -90), 6, Color("f1c40f"))
	if _near:
		draw_string(ThemeDB.fallback_font, Vector2(-90, -110), "S / ↓  Style & checkpoint", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("2b2140"))
