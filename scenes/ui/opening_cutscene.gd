extends "res://scenes/ui/storyboard_cutscene.gd"
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

func _init() -> void:
	shots = SHOTS
	finished.connect(_start_destination)

func _start_destination() -> void:
	if return_to_menu:
		get_tree().change_scene_to_file(Progress.MAIN_MENU)
		return
	Progress.mark_opening_seen()
	var destination := target_index if Progress.is_unlocked(target_index) else 0
	get_tree().change_scene_to_file(Progress.LEVELS[destination].path)
