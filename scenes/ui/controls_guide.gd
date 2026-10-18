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
	dim.color = Color(0.16, 0.10, 0.22, 0.68)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1080, 620)
	panel.add_theme_stylebox_override("panel", UiTheme.card(UiTheme.CREAM, UiTheme.INK, 4, 26, 18))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(UiTheme.heading("A little teamwork goes a long way.", 34))
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
	basics.add_child(_text("LEVERS", "Twin-Tails: tap skill near a lever to move its platform. Tap again to bring it back. Holding the key does not repeatedly switch it.", 20))
	var combos := _page("Hair combos")
	for entry in [
		["01  CARRY & GLIDE", "Twin-Tails: hold skill beside your friend to pick them up. Jump and keep holding to glide together."],
		["02  LAUNCH", "Twin-Tails stands on Pompadour's head. Pompadour presses skill to launch her up."],
		["03  SLING DASH", "While hanging in midair, Pompadour presses skill to fling through gel. Twin-Tails follows the gap."],
		["04  HAIR CATCH", "Pompadour parries. Twin-Tails holds skill on the ground to catch the blue scissor; release to toss up."],
		["05  WARM AIR", "Glide into a hair dryer to rise - carrying your friend too, just slower. Riding on her head goes up fastest."],
	]:
		combos.add_child(_text(entry[0], entry[1], 18))
	var styles := _page("Story & checkpoints")
	for entry in [
		["01  ONE SNIP TOO MANY", "Two friends arrive at closing time, hoping for a fresh look. The barber leaves them with his robot assistant. Something's off: the assistant cuts too much, and their hair reveals unexpected powers."],
		["02  THE DOOR LOCKS", "The robot locks the front door and turns its scissors towards them. Pompadour steps in to protect Twin-Tails. She notices another way through the salon."],
		["03  TRUST ME", "They choose to run together. Glide, carry, launch and parry through the service rooms. Both friends must reach each green exit; nobody gets left behind."],
		["04  THE SERVICE ROUTE", "Fresh Cut leads to Return to Sender, then Wash & Blow-Dry. These are rooms along the escape, where the same two friends learn to use their new powers together."],
		["05  THE ASSISTANT", "The runaway robot and its backup block the back door. Daze it with a parried scissor or a wall crash, then land on its glowing head. Escape together when it powers down."],
		["CHAIRS & CHECKPOINTS", "Bring both friends near a chair and press S / ↓. Swap the two familiar haircuts or keep your roles. Saving heals, dries off, and keeps your chosen pair on a room restart."],
		["SOMETHING'S OFF...", "The surprise chair and the assistant's damaging scissors can swap your two haircuts. Your movement keys stay yours; skills follow the haircut. Check your portrait and skill hints, then help each other adapt."],
	]:
		styles.add_child(_text(entry[0], entry[1], 18))
	var about := _page("About")
	about.add_child(UiTheme.heading("Oh No My Hair!", 38))
	about.add_child(_text("CREATED FOR", "GameJamPlus 26/27\nNPC Union\nSingapore", 26))
	about.add_child(_text("BAD HAIR. GOOD FRIENDS.", "One bad haircut. Two good friends. Escape the salon together.\nUse the other tabs for controls, hair combos and checkpoints.", 23))
	var navigation := _page("Shortcuts")
	for entry in [
		["ALL MENUS", "Arrow keys / Tab: move focus. Shift + Tab: previous control.\nEnter / Space: activate the focused button. Mouse: point and click."],
		["TITLE & CHAPTERS", "I: watch the opening from the title. F1 / H: open this shortcut guide.\nChapter menu: ← / → or 1–4 (also numpad) selects an unlocked chapter. P plays it. Esc goes back."],
		["PLAYING & PAUSING", "Esc: pause / resume. R: restart the current room, including from pause or death.\nF1 / H: pause and open help. Esc from help returns to pause; Esc again resumes."],
		["CHAIRS & TEAMWORK", "S / ↓ near a chair: open styling and checkpoints when both friends are nearby.\nHold S / ↓ to drop through shelves; press down to let go when carried. In chair menus, Tab / arrows select, Enter confirms, Esc cancels."],
		["OPENING & HELP", "Any key, mouse click or controller button skips the opening. Replay returns to the title.\nIn help: Page Up / Page Down or mouse wheel scrolls. Focus the tabs and use ← / → to switch pages. Esc / F1 / H closes help."],
	]:
		navigation.add_child(_text(entry[0], entry[1], 20))
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


func open(tab: int = 0) -> void:
	_tabs.current_tab = tab
	show()
	UiTheme.focus_if_visible.call_deferred(_close)


func dismiss() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("show_help"):
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
	col.add_child(UiTheme.heading("P1  /  TWIN-TAILS" if id == 1 else "P2  /  POMPADOUR", 25))
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
