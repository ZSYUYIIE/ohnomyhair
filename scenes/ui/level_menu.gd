class_name LevelMenu
extends CanvasLayer
## In-level overlay: the death popup, the pause menu and the final level's results.
## Runs while the tree is paused. Arrow keys / Enter (or the mouse) pick a button;
## R restarts the room straight from the death popup or the pause menu.

signal chosen(action: String)  # "restart", "menu", "resume", "next", "replay"

var _dim: ColorRect
var _panel: PanelContainer
var _box: VBoxContainer
var _can_resume := false
var _can_restart := false
var _guide: Control
const Guide := preload("res://scenes/ui/controls_guide.gd")


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UiTheme.get_theme()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0.16, 0.10, 0.22, 0.62)
	root.add_child(_dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(540, 0)
	_panel.add_theme_stylebox_override("panel", UiTheme.card(UiTheme.CREAM, UiTheme.INK, 4, 26, 24))
	center.add_child(_panel)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 12)
	_panel.add_child(_box)
	_guide = Guide.new()
	root.add_child(_guide)
	_guide.hide()
	_guide.closed.connect(func():
		_panel.show()
		for button in _box.get_children():
			if button is Button and button.text == "How to play & combos":
				UiTheme.focus_if_visible.call_deferred(button)
	)
	hide()


func is_open() -> bool:
	return visible


## Death popup: someone got snipped. Restart the room or leave.
func show_death(who: String) -> void:
	_can_resume = false
	_can_restart = true
	_open("Bad haircut!", "%s got snipped. Press R to try the room again." % who,
			[["Restart room", "restart"], ["Main menu", "menu"]])


func show_pause(level_title: String, room_title: String) -> void:
	_can_resume = true
	_can_restart = true
	_open("Paused", "%s\n%s" % [level_title, room_title],
			[["Resume", "resume"], ["How to play & combos", "help"], ["Restart room", "restart"], ["Main menu", "menu"]])


## stats: {time, deaths, best_time, new_best, has_next, ending}
func show_results(level_title: String, stats: Dictionary) -> void:
	_can_resume = false
	_can_restart = false
	var lines := "Time   %s%s\nDeaths   %d\nBest   %s" % [
		Progress.format_time(stats.time), "   NEW BEST!" if stats.new_best else "",
		stats.deaths, Progress.format_time(stats.best_time)]
	if stats.get("ending", "") != "":
		lines = stats.ending + "\n\n" + lines
	var buttons := []
	if stats.has_next:
		buttons.append(["Next level", "next"])
	buttons.append(["Play again", "replay"])
	buttons.append(["Main menu", "menu"])
	_open(level_title + " - CLEAR!", lines, buttons)


func close() -> void:
	_guide.hide()
	hide()


func show_room_results(room_title: String, seconds: float, deaths: int) -> void:
	_can_resume = false
	_can_restart = false
	_open(room_title + " - CLEAR!", "Time   %s\nDeaths   %d\nRoom replay · Chapter records unchanged" % [Progress.format_time(seconds), deaths],
		[["Replay room", "replay"], ["Choose another room", "rooms"], ["Main menu", "menu"]])


## Presses the button with this label (used by tests and by gamepads later).
func press(label: String) -> void:
	for b in _box.get_children():
		if b is Button and b.text == label:
			b.pressed.emit()
			return
	push_error("LevelMenu has no button '%s'" % label)


func button_labels() -> Array[String]:
	var out: Array[String] = []
	for b in _box.get_children():
		if b is Button:
			out.append(b.text)
	return out


func _open(title: String, body: String, buttons: Array) -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	_guide.hide()
	_panel.show()
	var t := UiTheme.heading(title, 40, UiTheme.PINK.darkened(0.18))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(t)
	var b := UiTheme.label(body, 20)
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(420, 0)
	_box.add_child(b)
	var focus_buttons: Array[Button] = []
	for entry in buttons:
		var button := Button.new()
		button.text = entry[0]
		button.custom_minimum_size = Vector2(0, 48)
		button.pressed.connect(_on_pressed.bind(entry[1]))
		_box.add_child(button)
		focus_buttons.append(button)
	show()
	UiTheme.focus_loop(focus_buttons)
	UiTheme.focus_if_visible.call_deferred(focus_buttons[0])


func _on_pressed(action: String) -> void:
	if action == "help":
		_panel.hide()
		_guide.open()
		return
	hide()
	chosen.emit(action)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _guide.visible:
		return
	if _can_resume and event.is_action_pressed("show_help"):
		get_viewport().set_input_as_handled()
		_on_pressed("help")
		_guide._tabs.current_tab = 4
		return
	if _can_restart and event.is_action_pressed("restart"):
		get_viewport().set_input_as_handled()
		_on_pressed("restart")
	elif _can_resume and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
		_on_pressed("resume")
