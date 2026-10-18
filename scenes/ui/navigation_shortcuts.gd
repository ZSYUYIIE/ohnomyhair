class_name NavigationShortcuts
extends RefCounted
## Named menu actions, separate from both players' movement and ability bindings.
const BINDINGS := {
	"show_help": [KEY_F1, KEY_H],
	"menu_play": [KEY_P],
	"menu_opening": [KEY_I],
	"chapter_1": [KEY_1, KEY_KP_1],
	"chapter_2": [KEY_2, KEY_KP_2],
	"chapter_3": [KEY_3, KEY_KP_3],
	"chapter_4": [KEY_4, KEY_KP_4],
}

static func install() -> void:
	for action in BINDINGS:
		if InputMap.has_action(action): continue
		InputMap.add_action(action)
		for code in BINDINGS[action]:
			var event := InputEventKey.new()
			event.keycode = code
			InputMap.action_add_event(action, event)
