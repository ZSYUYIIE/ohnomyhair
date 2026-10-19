extends Control
## Supplied 1672x941 map, fitted as one Control canvas so art and hit regions scale together.
signal chapter_selected(index: int)
signal play_requested
signal back_requested
signal opening_requested
signal rooms_requested

const DESIGN := Vector2(1672, 941)
const ART := "res://assets/art/ui/salon_map/"
const HIT_RECTS := [Rect2(101, 318, 386, 317), Rect2(528, 105, 306, 234), Rect2(947, 355, 346, 237), Rect2(1328, 120, 257, 281)]
const NAME_RECTS := [Rect2(185, 638, 300, 60), Rect2(529, 350, 286, 60), Rect2(947, 598, 319, 60), Rect2(1328, 413, 257, 60)]
const BADGE_POS := [Vector2(107, 391), Vector2(560, 159), Vector2(984, 366), Vector2(1361, 125)]
const PLATFORM_RECTS := [Rect2(190, 524, 288, 163), Rect2(534, 249, 184, 116), Rect2(952, 469, 273, 142), Rect2(1353, 316, 214, 110)]
# Feet sit on the near half of each ellipse, clear of the title pills and badges.
const MARKER_FEET := [Vector2(331, 618), Vector2(621, 322), Vector2(1058, 557), Vector2(1450, 382)]
const MARKER_WIDTHS := [250.0, 145.0, 190.0, 165.0]

var canvas: Control
var buttons: Array[Button] = []
var hit_areas: Array[Button] = []
var badges: Array[TextureRect] = []
var locks: Array[TextureRect] = []
var checks: Array[TextureRect] = []
var platforms: Array[TextureRect] = []
var marker: Control
var _marker_stage := -1
var _marker_tween: Tween
var back: Button
var opening_button: Button
var rooms_button: Button
var play_button: Button
var stage_name: Label
var stage_detail: Label
var footer: VBoxContainer
var shortcuts: Label
var info_panel: PanelContainer
var toast: Label
var _toast_timer: Timer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var matte := ColorRect.new()
	matte.color = Color("efcddd")
	matte.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	matte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(matte)
	canvas = Control.new()
	canvas.name = "MapCanvas"
	canvas.size = DESIGN
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canvas)
	_picture("map_neutral.png", Rect2(Vector2.ZERO, DESIGN))
	for rect: Rect2 in PLATFORM_RECTS:
		var platform := _picture("map_gold_platforms.png", rect)
		var patch := AtlasTexture.new()
		patch.atlas = platform.texture
		patch.region = rect
		platform.texture = patch
		platforms.append(platform)
	for i in Progress.LEVELS.size():
		var area := Button.new()
		area.name = "Stage%dHitArea" % (i + 1)
		# The whole illustrated stop is clickable, including the platform's front edge
		# and the small space before its name pill. The old art bounds left dead strips.
		var target: Rect2 = HIT_RECTS[i].merge(PLATFORM_RECTS[i]).merge(NAME_RECTS[i])
		area.position = target.position
		area.size = target.size
		area.focus_mode = Control.FOCUS_NONE
		for state in ["normal", "hover", "pressed", "focus"]:
			area.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		area.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		canvas.add_child(area)
		area.pressed.connect(_choose.bind(i))
		area.mouse_entered.connect(_preview.bind(i, true))
		area.mouse_exited.connect(_preview.bind(i, false))
		hit_areas.append(area)
		var button := _button("", NAME_RECTS[i], 30)
		button.pressed.connect(_choose.bind(i))
		buttons.append(button)
		badges.append(_picture("png/badge_gold.png", Rect2(BADGE_POS[i], Vector2(76, 76))))
		var number := _label(str(i + 1), Rect2(BADGE_POS[i], Vector2(76, 70)), 46)
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		locks.append(_picture("png/icon_lock.png", Rect2(BADGE_POS[i] + Vector2(49, 43), Vector2(40, 48))))
		checks.append(_picture("png/icon_check.png", Rect2(BADGE_POS[i] + Vector2(49, 43), Vector2(40, 40))))
	_build_marker()
	back = _button("‹  Back", Rect2(1432, 17, 214, 86), 38)
	_style_button(back, "cream")
	back.pressed.connect(func(): back_requested.emit())
	opening_button = _button("Story", Rect2(1220, 17, 198, 86), 34)
	_style_button(opening_button, "cream")
	opening_button.pressed.connect(func(): opening_requested.emit())
	rooms_button = _button("Rooms", Rect2(1008, 17, 198, 86), 34)
	_style_button(rooms_button, "cream")
	rooms_button.visible = Progress.campaign_completed()
	rooms_button.pressed.connect(func(): rooms_requested.emit())
	# Containers reserve separate space for records and shortcuts, even with large best times.
	footer = VBoxContainer.new()
	footer.name = "MapFooter"
	footer.position = Vector2(42, 757)
	footer.size = Vector2(1588, 166)
	footer.add_theme_constant_override("separation", 14)
	canvas.add_child(footer)
	info_panel = PanelContainer.new()
	info_panel.custom_minimum_size.y = 128
	var panel_skin := _skin("panel_info")
	panel_skin.content_margin_left = 40
	panel_skin.content_margin_right = 20
	panel_skin.content_margin_top = 12
	panel_skin.content_margin_bottom = 12
	info_panel.add_theme_stylebox_override("panel", panel_skin)
	footer.add_child(info_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	info_panel.add_child(row)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 0)
	row.add_child(col)
	stage_name = UiTheme.heading("", 48, Color("250d39"))
	col.add_child(stage_name)
	stage_detail = UiTheme.label("", 26, Color("6d4c70"))
	col.add_child(stage_detail)
	play_button = _button("Play  ▶", Rect2(), 46, false)
	play_button.custom_minimum_size = Vector2(320, 104)
	_style_button(play_button, "gold")
	row.add_child(play_button)
	play_button.pressed.connect(func(): play_requested.emit())
	shortcuts = UiTheme.label("← → / Tab  Select   ·   1–4  Chapter   ·   P  Play   ·   I  Story   ·   Esc  Back   ·   F1 / H  Help", 22, Color("250d39"))
	shortcuts.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shortcuts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.add_child(shortcuts)
	toast = _label("", Rect2(370, 704, 940, 44), 25)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_stylebox_override("normal", UiTheme.card(UiTheme.CREAM, UiTheme.INK, 2, 16, 4))
	toast.hide()
	_toast_timer = Timer.new()
	_toast_timer.one_shot = true
	_toast_timer.wait_time = 2.8
	_toast_timer.timeout.connect(toast.hide)
	add_child(_toast_timer)
	resized.connect(_fit)
	_fit()

func _fit() -> void:
	if not is_instance_valid(canvas): return
	var factor := minf(size.x / DESIGN.x, size.y / DESIGN.y)
	canvas.scale = Vector2.ONE * factor
	canvas.position = (size - DESIGN * factor) / 2.0

func refresh(selected: int, names: Array[String]) -> void:
	_move_marker(selected)
	for i in buttons.size():
		var unlocked := Progress.is_unlocked(i)
		var cleared := Progress.is_cleared(i) and unlocked
		buttons[i].disabled = not unlocked
		buttons[i].text = names[i]
		var hint := names[i] if unlocked else "Complete chapter %d to unlock" % i
		buttons[i].tooltip_text = hint
		hit_areas[i].tooltip_text = hint
		_style_pill(buttons[i], "gold" if selected == i else ("cream" if unlocked else "lavender"))
		platforms[i].visible = selected == i
		buttons[i].modulate = Color.WHITE
		badges[i].texture = load(ART + "png/badge_%s.png" % ("complete" if cleared else ("gold" if unlocked else "lavender")))
		locks[i].visible = not unlocked
		checks[i].visible = cleared
	toast.hide()
	_toast_timer.stop()

func _preview(index: int, hovered: bool) -> void:
	# Gold belongs to the chosen destination; hovering another stop does not claim it.
	buttons[index].modulate = Color("fff0d9") if hovered and Progress.is_unlocked(index) else Color.WHITE

func _build_marker() -> void:
	marker = Control.new()
	marker.name = "TravelingFriends"
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(marker)
	var friends := TextureRect.new()
	var cutout := AtlasTexture.new()
	cutout.atlas = load(ART + "friends_marker.png")
	cutout.region = Rect2(140, 160, 1260, 790)
	friends.texture = cutout
	friends.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	friends.size = Vector2(250, 250.0 * 790.0 / 1260.0)
	friends.position = Vector2(-friends.size.x / 2.0, -friends.size.y)
	friends.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cleanup := ShaderMaterial.new()
	cleanup.shader = preload("res://scenes/ui/map_marker.gdshader")
	friends.material = cleanup
	marker.add_child(friends)

func _move_marker(index: int) -> void:
	if index == _marker_stage: return
	if _marker_tween and _marker_tween.is_valid(): _marker_tween.kill()
	var target: Vector2 = MARKER_FEET[index]
	var target_scale: Vector2 = Vector2.ONE * MARKER_WIDTHS[index] / 250.0
	if _marker_stage < 0:
		marker.position = target
		marker.scale = target_scale
	else:
		var start := marker.position
		_marker_tween = create_tween()
		_marker_tween.set_parallel(true)
		_marker_tween.tween_method(func(t: float):
			marker.position = start.lerp(target, t) + Vector2(0, -sin(t * PI) * 30.0), 0.0, 1.0, 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_marker_tween.tween_property(marker, "scale", target_scale, 0.32)
		_marker_tween.chain().tween_property(marker, "scale", target_scale * Vector2(1.04, 0.96), 0.07)
		_marker_tween.chain().tween_property(marker, "scale", target_scale, 0.12).set_trans(Tween.TRANS_SINE)
	_marker_stage = index

func _choose(index: int) -> void:
	if Progress.is_unlocked(index):
		buttons[index].grab_focus()
		chapter_selected.emit(index)
	else:
		toast.text = "Complete chapter %d to unlock this stop." % index
		toast.show()
		_toast_timer.start()

func _button(text: String, rect: Rect2, font_size: int, attach := true) -> Button:
	var button := Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.add_theme_font_size_override("font_size", font_size)
	UiTheme.wire_button(button)
	if attach: canvas.add_child(button)
	return button

func _style_pill(button: Button, color: String) -> void:
	button.add_theme_stylebox_override("normal", _skin("pill_" + color))
	button.add_theme_stylebox_override("hover", _skin("pill_gold"))
	button.add_theme_stylebox_override("pressed", _skin("pill_lavender"))
	button.add_theme_stylebox_override("disabled", _skin("pill_lavender"))
	_focus_style(button)

func _style_button(button: Button, color: String) -> void:
	for state in ["normal", "hover", "pressed"]:
		button.add_theme_stylebox_override(state, _skin("button_" + color + "_" + state))
	button.add_theme_stylebox_override("disabled", _skin("button_disabled"))
	_focus_style(button)

func _focus_style(button: Button) -> void:
	# Every illustrated map button keeps its original silhouette on keyboard focus.
	# The shared pop animation and hover/pressed artwork provide interaction feedback.
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", Color("250d39"))

func _skin(asset: String) -> StyleBoxTexture:
	var skin := StyleBoxTexture.new()
	skin.texture = load(ART + "png/" + asset + ".png")
	skin.set_content_margin_all(4)
	return skin

func _picture(asset: String, rect: Rect2) -> TextureRect:
	var picture := TextureRect.new()
	picture.texture = load(ART + asset)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	picture.position = rect.position
	picture.size = rect.size
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(picture)
	return picture

func _label(text: String, rect: Rect2, font_size: int) -> Label:
	var label := UiTheme.heading(text, font_size, Color("250d39"))
	label.position = rect.position
	label.size = rect.size
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(label)
	return label
