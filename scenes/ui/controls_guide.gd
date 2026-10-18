extends Control
## Shared help for title and pause. Keyboard focus stays inside the guide.

signal closed

var _tabs: TabContainer
var _close: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.get_theme()
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.12, 0.08, 0.18, 0.78)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1080, 620)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(UiTheme.label("A little teamwork goes a long way.", 32))
	box.add_child(UiTheme.label("Skills follow the haircut. Mouse wheel / Page Down to scroll for more.", 20, UiTheme.MUTED))
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_tabs)
	var basics := _page("The basics")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	basics.add_child(row)
	row.add_child(_player_keys(1))
	row.add_child(_player_keys(2))
	basics.add_child(_text("THE GOAL", "Both friends must stand in the green exit to leave a room.\nHearts are your hair: lose them all and you both restart the room.", 20))
	basics.add_child(_text("ROOM SHORTCUTS", "Esc  Pause / resume     R  Restart room\nHold S / ↓ to drop through shelves. Press down to let go when carried.", 20))
	var combos := _page("Hair combos")
	for entry in [
		["01  CARRY & GLIDE", "Twin-Tails: hold skill beside your friend to pick them up. Jump and keep holding to glide together."],
		["02  LAUNCH", "Twin-Tails stands on Pompadour's head. Pompadour presses skill to launch her up."],
		["03  SLING DASH", "While hanging in midair, Pompadour presses skill to fling through gel. Twin-Tails follows the gap."],
		["04  HAIR CATCH", "Pompadour parries. Twin-Tails holds skill on the ground to catch the blue scissor; release to toss up."],
		["05  HAIR-COPTER", "Pompadour stands on Twin-Tails' head. Hold Twin-Tails' skill in warm air to lift both. Carrying hovers."],
	]:
		combos.add_child(_text(entry[0], entry[1], 18))
	var styles := _page("New styles & chairs")
	for entry in [
		["AFRO — SPRING / SHIELD", "Hold skill to charge; release with a friend on your head to bounce them up. Hold attack for a short shield or to catch a parried scissor. Release to send it back."],
		["CANNONBALL — AFRO + POMPADOUR", "Afro charges skill. Pompadour stands on Afro's head and holds skill too. Afro releases: Pompadour becomes a drill through reinforced gel and dazes the boss."],
		["LONG STRAIGHT — ROPE / HOOK / LASSO", "Hold skill on a ledge to lower a rope. Your friend holds jump to climb; left/right releases with a boost. In the air, skill hooks a gold ring. Attack lassos bots or levers."],
		["STYLE & CHECKPOINT", "Bring both friends near a chair and press S / ↓. Choose each haircut and save to heal, dry off, and keep those styles when restarting this room."],
		["SOMETHING'S OFF...", "Tony's scissors change your haircut if they hurt you. Watch your portrait and skill hints! Wet Afro hair cannot spring or shield; find a dryer."],
	]:
		styles.add_child(_text(entry[0], entry[1], 18))
	_close = Button.new()
	_close.text = "Got it  /  Esc"
	_close.custom_minimum_size.y = 48
	_close.pressed.connect(dismiss)
	box.add_child(_close)
	var bar := _tabs.get_tab_bar()
	_tabs.add_theme_stylebox_override("tab_selected", UiTheme.card(Color("f9e39b"), UiTheme.WALNUT, 2, 8, 10))
	_tabs.add_theme_stylebox_override("tab_unselected", UiTheme.card(Color("eee6e1"), Color("c5b9c5"), 1, 8, 10))
	_tabs.add_theme_color_override("font_selected_color", UiTheme.INK)
	_tabs.add_theme_color_override("font_unselected_color", UiTheme.MUTED)
	_tabs.add_theme_stylebox_override("tab_focus", theme.get_stylebox("focus", "Button"))
	bar.focus_mode = Control.FOCUS_ALL
	bar.focus_next = _close.get_path()
	bar.focus_previous = _close.get_path()
	bar.focus_neighbor_bottom = _close.get_path()
	_close.focus_next = bar.get_path()
	_close.focus_previous = bar.get_path()
	_close.focus_neighbor_top = bar.get_path()
	_close.focus_neighbor_bottom = bar.get_path()
	_close.focus_neighbor_left = _close.get_path()
	_close.focus_neighbor_right = _close.get_path()


func open() -> void:
	_tabs.current_tab = 0
	show()
	UiTheme.focus_if_visible.call_deferred(_close)


func dismiss() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event.is_action_pressed("ui_cancel"):
		dismiss()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_page_down") or event.is_action_pressed("ui_page_up"):
		var scroll := _tabs.get_current_tab_control().get_child(0) as ScrollContainer
		scroll.scroll_vertical += 220 if event.is_action_pressed("ui_page_down") else -220
		get_viewport().set_input_as_handled()


func _page(title: String) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.name = title
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 14)
	_tabs.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	scroll.add_child(box)
	return box


func _player_keys(id: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", UiTheme.card(Color("fce3ed") if id == 1 else Color("e2effa"), UiTheme.WALNUT, 2, 10, 14))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)
	col.add_child(UiTheme.label("P1  /  TWIN-TAILS" if id == 1 else "P2  /  POMPADOUR", 24))
	col.add_child(UiTheme.label("A / D   Move     W   Jump\nG   Hold: glide / carry   Tap: lever\nF   Hair whip to stun" if id == 1 else "← / →   Move     ↑   Jump\nK   Dash / launch a friend\nL   Parry flying scissors", 20))
	return panel


func _text(title: String, body: String, font_size: int) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.add_child(UiTheme.label(title, 16, UiTheme.MUTED))
	var text := UiTheme.label(body, font_size)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(text)
	return col
