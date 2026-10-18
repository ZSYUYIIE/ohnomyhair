extends "res://scenes/ui/storyboard_cutscene.gd"
## Supplied ending v1: seven panels, six subtitles and a 25-second timeline.
const SHOTS := [
	{"texture": preload("res://assets/art/ending/ending_01_we_did_it.png"), "seconds": 3.0, "subtitle": "We actually did it.", "zoom_end": 1.03},
	{"texture": preload("res://assets/art/ending/ending_02_good_friends.png"), "seconds": 3.0, "subtitle": ""},
	{"texture": preload("res://assets/art/ending/ending_03_barber_returns.png"), "seconds": 3.0, "subtitle": "I was only gone a minute..."},
	{"texture": preload("res://assets/art/ending/ending_04_fix_your_hair.png"), "seconds": 4.0, "subtitle": "The barber offers to fix your hair.", "zoom_end": 1.03},
	{"texture": preload("res://assets/art/ending/ending_05_look_at_each_other.png"), "seconds": 4.0, "subtitle": "You look at each other..."},
	{"texture": preload("res://assets/art/ending/ending_06_and_say_no.png"), "seconds": 4.0, "subtitle": "...and say no."},
	{"texture": preload("res://assets/art/ending/ending_07_bad_hair_good_friends.png"), "seconds": 4.0, "subtitle": "Bad hair. Good friends.", "zoom_end": 1.03, "fade_out": 0.5},
]

func _init() -> void:
	shots = SHOTS
