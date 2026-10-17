class_name MainMenu
extends Control
## Title screen: the two friends, a card per level (locked until the previous one is
## cleared, with best time and fewest deaths), Controls and Quit. Keyboard: arrows + Enter.

var _cards: Array[PanelContainer] = []
var _close_button: Button
var _play_buttons: Array[Button] = []
var _controls: Control


func _ready() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.get_theme()
	_build_backdrop()

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 18)
	add_child(col)

	var title := UiTheme.label("OH NO MY HAIR", 72, UiTheme.PINK)
	title.add_theme_color_override("font_outline_color", UiTheme.WALNUT)
	title.add_theme_constant_override("outline_size", 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var subtitle := UiTheme.label("Two friends. Two terrible haircuts. One barber shop to escape.", 22)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(subtitle)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	col.add_child(row)
	for i in Progress.LEVELS.size():
		row.add_child(_level_card(i))

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	col.add_child(buttons)
	var controls := _button("Controls & combos", _toggle_controls)
	buttons.add_child(controls)
	buttons.add_child(_button("Quit", func(): get_tree().quit()))

	_controls = _controls_panel()
	add_child(_controls)
	_controls.hide()
	_focus_latest()


## The furthest unlocked level's Play button.
func _focus_latest() -> void:
	for i in range(_play_buttons.size() - 1, -1, -1):
		if not _play_buttons[i].disabled:
			_play_buttons[i].grab_focus.call_deferred()
			return


func play(index: int) -> void:
	get_tree().change_scene_to_file(Progress.LEVELS[index].path)


func _level_card(i: int) -> PanelContainer:
	var unlocked := Progress.is_unlocked(i)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(270, 190)
	if not unlocked:
		card.add_theme_stylebox_override("panel", UiTheme.card(Color("ece3d8"), Color("b9a998")))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)
	box.add_child(UiTheme.label("LEVEL %d" % (i + 1), 16, Color(UiTheme.INK, 0.6)))
	box.add_child(UiTheme.label(Progress.LEVELS[i].title, 28, UiTheme.INK if unlocked else Color("a3968a")))
	var info := ""
	if not unlocked:
		info = "Clear Level %d to unlock" % i
	elif Progress.is_cleared(i):
		info = "Best  %s\nFewest deaths  %d" % [Progress.format_time(Progress.best_time(i)), Progress.best_deaths(i)]
	else:
		info = "Not cleared yet\n "
	box.add_child(UiTheme.label(info, 16, Color(UiTheme.INK, 0.8)))
	var play_button := _button("Play" if unlocked else "Locked", play.bind(i))
	play_button.disabled = not unlocked
	box.add_child(play_button)
	_cards.append(card)
	_play_buttons.append(play_button)
	return card


## Full-screen dimmed overlay with the controls card centered on it.
func _controls_panel() -> Control:
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.1, 0.06, 0.08, 0.55)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(860, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(UiTheme.label("Controls", 32, UiTheme.PINK.darkened(0.2)))
	box.add_child(UiTheme.label(
		"P1 (starts as Twin-Tails):   A / D move   W jump   G skill   F attack\n" +
		"P2 (starts as Pompadour):   Arrows move   Up jump   K skill   L attack\n" +
		"Esc pause   R restart room   Down: let go when carried / drop through a shelf", 18))
	box.add_child(UiTheme.label("Skills follow the haircut, not the player.", 18, UiTheme.PINK.darkened(0.2)))
	box.add_child(UiTheme.label(
		"Twin-Tails   skill: hold to glide, grab your friend, pull a lever    attack: hair whip (stun)\n" +
		"Pompadour   skill: dash through gel, launch a friend off your head    attack: parry scissors", 18))
	box.add_child(UiTheme.label("Hair combos", 24, UiTheme.INK))
	box.add_child(UiTheme.label(
		"Carry - Twin-Tails holds skill next to Pompadour and glides with her.\n" +
		"Launch - Twin-Tails stands on Pompadour's head; Pompadour presses skill.\n" +
		"Sling Dash - while hanging, Pompadour presses skill: flung through the air and through gel.\n" +
		"Volley - Pompadour parries (scissor turns blue), Twin-Tails whips it straight up (gold).", 18))
	_close_button = _button("Close", _toggle_controls)
	box.add_child(_close_button)
	return overlay


func _toggle_controls() -> void:
	_controls.visible = not _controls.visible
	if _controls.visible:
		_close_button.grab_focus()
	else:
		_focus_latest()


func _button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 46)
	b.pressed.connect(on_press)
	return b


## Salon wall with mirrors and barber poles, a checkered floor, and the two friends.
func _build_backdrop() -> void:
	var wall := ColorRect.new()
	wall.set_anchors_preset(Control.PRESET_FULL_RECT)
	wall.color = Color("f6e7ec")
	add_child(wall)
	var decor := SalonDecor.new()
	decor.wall_color = wall.color
	decor.layout_seed = 7
	add_child(decor)
	var floor_strip := Floor.new()
	floor_strip.anchor_top = 1.0
	floor_strip.anchor_bottom = 1.0
	floor_strip.anchor_right = 1.0
	floor_strip.offset_top = -90.0
	add_child(floor_strip)
	for side in [[Vector2(90, 470), TwinTails.new()], [Vector2(1100, 470), Pompadour.new()]]:
		var hair: HairAbility = side[1]
		var portrait := Hud.Portrait.new()
		portrait.set_colors(hair.body_color, hair.HAIR_COLOR)
		portrait.position = side[0]
		portrait.scale = Vector2(3, 3)
		add_child(portrait)
		hair.free()


class Floor extends Control:
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("7a4e33"))
		for cx in int(size.x / 12.0) + 1:
			for cy in 2:
				var c := Color("26262b") if (cx + cy) % 2 == 0 else Color("efeae2")
				draw_rect(Rect2(cx * 12, cy * 12, 12, 12), c)
