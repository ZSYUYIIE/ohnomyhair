extends Control
## The teammate's 11 clean panels; transitions stay inside the 39-second timeline.
const SHOTS := [
	{"texture": preload("res://assets/art/opening/cutscene_01_closing_time.png"), "seconds": 4.0, "subtitle": "Two friends. One last chance for a great haircut.", "wide": true},
	{"texture": preload("res://assets/art/opening/cutscene_02_robot_assistant.png"), "seconds": 3.0, "subtitle": "Back in a moment. My assistant will handle everything.", "wide": true},
	{"texture": preload("res://assets/art/opening/cutscene_03_good_hair_day.png"), "seconds": 4.0, "subtitle": "A fresh look. That's all we wanted.", "wide": false},
	{"texture": preload("res://assets/art/opening/cutscene_04_robot_malfunction.png"), "seconds": 4.0, "subtitle": "Something's off.", "wide": false},
	{"texture": preload("res://assets/art/opening/cutscene_05_hair_burst.png"), "seconds": 2.0, "subtitle": "That was definitely too much.", "wide": false},
	{"texture": preload("res://assets/art/opening/cutscene_06_power_hair_reveal.png"), "seconds": 5.0, "subtitle": "Our hair has other plans.", "wide": false},
	{"texture": preload("res://assets/art/opening/cutscene_07_door_lock.png"), "seconds": 3.0, "subtitle": "The front door is locked.", "wide": false},
	{"texture": preload("res://assets/art/opening/cutscene_08_protect_friend.png"), "seconds": 3.0, "subtitle": "Hey! Stay away from my friend!", "wide": true},
	{"texture": preload("res://assets/art/opening/cutscene_09_another_way.png"), "seconds": 3.0, "subtitle": "Wait. There's another way.", "wide": false},
	{"texture": preload("res://assets/art/opening/cutscene_10_trust_me.png"), "seconds": 4.0, "subtitle": "Trust me.", "wide": false},
	{"texture": preload("res://assets/art/opening/cutscene_11_escape_together.png"), "seconds": 4.0, "subtitle": "Today, we just wanted a good haircut.", "wide": true},
]

var target_index := 0
var return_to_menu := false
var _shot_index := 0
var _shot_elapsed := 0.0
var _elapsed := 0.0
var _finished := false
var _image: TextureRect
var _subtitle: Label
var _counter: Label
var _skip: Button

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
	var strip := ColorRect.new()
	strip.color = Color(0.13, 0.07, 0.20, 0.88)
	strip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	strip.offset_top = -140
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(strip)
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
	while _shot_elapsed >= SHOTS[_shot_index].seconds:
		_shot_elapsed -= SHOTS[_shot_index].seconds
		_shot_index += 1
		if _shot_index >= SHOTS.size():
			_finish()
			return
		_show_shot()
	# Subtle pushes on wide shots; close-ups keep their supplied framing.
	var zoom := lerpf(1.0, 1.025, _shot_elapsed / SHOTS[_shot_index].seconds) if SHOTS[_shot_index].wide else 1.0
	_image.pivot_offset = size / 2.0
	_image.scale = Vector2.ONE * zoom
	_image.modulate.a = minf(1.0, _shot_elapsed / 0.18)

func _show_shot() -> void:
	_image.texture = SHOTS[_shot_index].texture
	_subtitle.text = SHOTS[_shot_index].subtitle
	_counter.text = "%02d / %02d" % [_shot_index + 1, SHOTS.size()]

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
	if return_to_menu:
		get_tree().change_scene_to_file(Progress.MAIN_MENU)
		return
	Progress.mark_opening_seen()
	var destination := target_index if Progress.is_unlocked(target_index) else 0
	get_tree().change_scene_to_file(Progress.LEVELS[destination].path)
