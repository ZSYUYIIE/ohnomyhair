extends Control
## Shared CG player: click / any key advances; Esc / B / Start skips.
signal finished
var shots: Array = []

## Ignore input this long after the opening appears, so the click that started it doesn't count.
const INPUT_GRACE := 0.35
## Minimum time between page turns, so mashing or a held auto-repeat can't blow past panels.
const ADVANCE_COOLDOWN := 0.25
## Each panel fades in from black over this long.
const FADE_IN := 0.18

var _shot_index := 0
var _shot_elapsed := 0.0
var _elapsed := 0.0
var _next_advance_at := INPUT_GRACE
var _finished := false
var _image: TextureRect
var _subtitle: Label
var _counter: Label
var _strip: ColorRect
var _skip: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.get_theme()
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Let clicks fall through to this Control's _gui_input; only the Skip button catches its own.
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	_skip.text = "Skip  (Esc)"
	_skip.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_skip.offset_left = -255
	_skip.offset_right = -26
	_skip.offset_top = 22
	_skip.offset_bottom = 70
	# Mouse-only: keyboard and pad skip with Esc / B / Start, so Space and Enter stay "next page".
	_skip.focus_mode = Control.FOCUS_NONE
	_skip.pressed.connect(_try_skip)
	add_child(_skip)
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
	# Panels are native 1280x720 and stay at 1:1. Animating their scale resampled the art
	# at a new sub-pixel size every frame, which read as the picture shaking.
	_image.modulate.a = minf(1.0, _shot_elapsed / FADE_IN)
	var fade_out: float = shots[_shot_index].get("fade_out", 0.0)
	if fade_out > 0.0:
		_image.modulate.a = minf(_image.modulate.a, (shots[_shot_index].seconds - _shot_elapsed) / fade_out)

func _show_shot() -> void:
	_image.texture = shots[_shot_index].texture
	_image.modulate.a = minf(1.0, _shot_elapsed / FADE_IN)
	_subtitle.text = shots[_shot_index].subtitle
	_strip.visible = not _subtitle.text.is_empty()
	_counter.text = "%02d / %02d" % [_shot_index + 1, shots.size()]

## Keyboard and controller. Mouse clicks arrive through _gui_input so the Skip button keeps its own.
func _input(event: InputEvent) -> void:
	if _finished: return
	if event is InputEventKey:
		if not event.pressed or event.echo: return
		# Lone modifiers (e.g. Alt while Alt+Tabbing away) shouldn't turn pages.
		if event.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]: return
		get_viewport().set_input_as_handled()
		if event.keycode == KEY_ESCAPE:
			_try_skip()
		else:
			_advance()
	elif event is InputEventJoypadButton and event.pressed:
		get_viewport().set_input_as_handled()
		if event.button_index in [JOY_BUTTON_B, JOY_BUTTON_START]:
			_try_skip()
		else:
			_advance()

## Left clicks anywhere except the Skip button turn the page.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_advance()

## Jump to the next panel, or end the opening from the last one. Rate-limited by ADVANCE_COOLDOWN.
func _advance() -> void:
	if _finished or _elapsed < _next_advance_at: return
	_next_advance_at = _elapsed + ADVANCE_COOLDOWN
	_shot_index += 1
	_shot_elapsed = 0.0
	if _shot_index >= shots.size():
		_finish()
		return
	_show_shot()

func _try_skip() -> void:
	if _elapsed >= INPUT_GRACE: _finish()

func _finish() -> void:
	if _finished: return
	_finished = true
	finished.emit()
