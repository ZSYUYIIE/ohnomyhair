class_name LevelMenu
extends CanvasLayer
## In-level overlay: the death popup, the pause menu and the level-clear results.
## Runs while the tree is paused. Arrow keys / Enter (or the mouse) pick a button.

signal chosen(action: String)  # "restart", "menu", "resume", "next", "replay"

var _dim: ColorRect
var _panel: PanelContainer
var _box: VBoxContainer


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
	_dim.color = Color(0.1, 0.06, 0.08, 0.55)
	root.add_child(_dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(460, 0)
	center.add_child(_panel)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 12)
	_panel.add_child(_box)
	hide()


func is_open() -> bool:
	return visible


## Death popup: someone got snipped. Restart the room or leave.
func show_death(who: String) -> void:
	_open("Bad haircut!", "%s got snipped. The room resets when you restart." % who,
			[["Restart room", "restart"], ["Main menu", "menu"]])


func show_pause(level_title: String, room_title: String) -> void:
	_open("Paused", "%s\n%s" % [level_title, room_title],
			[["Resume", "resume"], ["Restart room", "restart"], ["Main menu", "menu"]])


## stats: {time, deaths, best_time, new_best, has_next, ending}
func show_results(level_title: String, stats: Dictionary) -> void:
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
	hide()


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
		c.queue_free()
	var t := UiTheme.label(title, 36, UiTheme.PINK.darkened(0.2))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(t)
	var b := UiTheme.label(body, 20)
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(420, 0)
	_box.add_child(b)
	var first: Button = null
	for entry in buttons:
		var button := Button.new()
		button.text = entry[0]
		button.custom_minimum_size = Vector2(0, 48)
		button.pressed.connect(_on_pressed.bind(entry[1]))
		_box.add_child(button)
		if first == null:
			first = button
	show()
	first.grab_focus.call_deferred()


func _on_pressed(action: String) -> void:
	hide()
	chosen.emit(action)
