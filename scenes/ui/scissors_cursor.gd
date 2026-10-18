extends Node
## Persistent hardware cursor: the fixed blade tip is the click point in both poses.
const OPEN := "res://assets/art/ui/cursor/scissors_open.svg"
const CLOSED := "res://assets/art/ui/cursor/scissors_closed.svg"
const HOTSPOT := Vector2(4, 6)
const SHAPES := [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND]

var _closed := false
var _focused := true
var _open_texture: Texture2D
var _closed_texture: Texture2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Defer texture loading until runtime so fresh editor imports can register the SVGs first.
	_open_texture = load(OPEN)
	_closed_texture = load(CLOSED)
	_set_closed(false, true)

func _input(event: InputEvent) -> void:
	if _focused and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_set_closed(event.pressed)

func _process(_delta: float) -> void:
	# CGs can consume clicks before this node receives _input; keep their pose in sync too.
	if _focused:
		_set_closed(Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))

func _exit_tree() -> void:
	if DisplayServer.get_name() != "headless":
		for shape in SHAPES:
			Input.set_custom_mouse_cursor(null, shape)
	_open_texture = null
	_closed_texture = null

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_focused = false
		_set_closed(false)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_focused = true

func _set_closed(closed: bool, force := false) -> void:
	if _closed == closed and not force:
		return
	_closed = closed
	if DisplayServer.get_name() == "headless":
		return
	# Only change native textures on a pose change, avoiding per-frame browser flicker.
	for shape in SHAPES:
		Input.set_custom_mouse_cursor(_closed_texture if closed else _open_texture, shape, HOTSPOT)
