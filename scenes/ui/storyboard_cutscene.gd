extends Control
## Shared full-screen CG player for the opening and ending. Durations include transitions.
signal finished

var shots: Array = []

var _shot_index := 0
var _shot_elapsed := 0.0
var _elapsed := 0.0
var _finished := false
var _image: TextureRect
var _subtitle: Label
var _counter: Label
var _skip: Button
var _strip: ColorRect

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.get_theme()
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(black)
	_image = TextureRect.new()
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_image)
	_strip = ColorRect.new()
	_strip.color = Color(0.13, 0.07, 0.20, 0.88)
	_strip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_strip.offset_top = -140
	_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_strip)
	_subtitle = UiTheme.label("", 28, UiTheme.CREAM)
	_subtitle.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_subtitle.offset_left = 70
	_subtitle.offset_right = -70
	_subtitle.offset_top = -126
	_subtitle.offset_bottom = -24
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_subtitle)
	_counter = UiTheme.label("", 19, UiTheme.CREAM)
	_counter.position = Vector2(30, 28)
	_counter.add_theme_color_override("font_outline_color", UiTheme.INK)
	_counter.add_theme_constant_override("outline_size", 5)
	add_child(_counter)
	_skip = Button.new()
	_skip.text = "Skip  /  any key"
	_skip.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_skip.offset_left = -255
	_skip.offset_right = -26
	_skip.offset_top = 22
	_skip.offset_bottom = 70
	_skip.pressed.connect(_try_skip)
	add_child(_skip)
	_skip.grab_focus()
	_show_shot()

func _process(delta: float) -> void:
	if _finished: return
	_elapsed += delta
	_shot_elapsed += delta
	while _shot_elapsed >= shots[_shot_index].seconds:
		_shot_elapsed -= shots[_shot_index].seconds
		_shot_index += 1
		if _shot_index >= shots.size():
			_finish()
			return
		_show_shot()
	# Subtle pushes on wide shots; close-ups keep their supplied framing.
	var shot: Dictionary = shots[_shot_index]
	var zoom_end: float = shot.get("zoom_end", 1.025 if shot.get("wide", false) else 1.0)
	var zoom := lerpf(1.0, zoom_end, _shot_elapsed / shot.seconds)
	_image.pivot_offset = size / 2.0
	_image.scale = Vector2.ONE * zoom
	_image.modulate.a = minf(1.0, _shot_elapsed / 0.18)
	var fade_out: float = shot.get("fade_out", 0.0)
	if fade_out > 0.0:
		_image.modulate.a = minf(_image.modulate.a, (shot.seconds - _shot_elapsed) / fade_out)

func _show_shot() -> void:
	_image.texture = shots[_shot_index].texture
	_image.scale = Vector2.ONE
	_image.modulate.a = 0.0
	_subtitle.text = shots[_shot_index].subtitle
	_strip.visible = not _subtitle.text.is_empty()
	_counter.text = "%02d / %02d" % [_shot_index + 1, shots.size()]

func _input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventKey:
		pressed = event.pressed and not event.echo and event.keycode not in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]
	elif event is InputEventMouseButton or event is InputEventJoypadButton:
		pressed = event.pressed
	if pressed and _elapsed >= 0.35:
		get_viewport().set_input_as_handled()
		_finish()

func _try_skip() -> void:
	if _elapsed >= 0.35: _finish()

func _finish() -> void:
	if _finished: return
	_finished = true
	finished.emit()
