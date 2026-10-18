class_name StyleRules
extends RefCounted
## Which haircut pairs a room allows, and what each pair can do: the vocabulary of the
## gate check (tests/test_gates.gd) and the gate graph (tools/gate_graph.gd).
## Design: docs/design/roster_and_chapters.md.
##
## A room lists `styles` (the haircuts its chair offers) and `gates` (its obstacles, each
## passable by ANY of a few verbs). Every distinct pair from `styles` must have a verb for
## every gate. Two friends never wear the same haircut.

const TT := Player.Hair.TWIN_TAILS
const POMP := Player.Hair.POMPADOUR

## Anyone can do these.
const UNIVERSAL: Array[String] = ["walk", "jump", "crash"]
## What one haircut can do with any friend.
const SOLO := {
	TT: ["glide", "carry", "lever", "whip", "hair_copter"],
	POMP: ["dash_gel", "parry", "launch"],
}
## Combos that need both haircuts of a specific pair.
const COMBOS := [
	{"verb": "sling", "needs": [TT, POMP]},
	{"verb": "catch_toss", "needs": [TT, POMP]},
]
## What each verb means, for the gate graph and the design doc.
const VERB_INFO := {
	"walk": "walk / take a timing window", "jump": "jump (3.5 tiles up, 6 across)",
	"crash": "bait a charge into a wall",
	"glide": "glide (12.5 tiles flat)", "carry": "carry a friend (8.9 flat, 16.5 from 6 up)",
	"lever": "pull a lever by hand", "whip": "whip-stun a bot", "hair_copter": "ride a glider up a dryer",
	"dash_gel": "dash through gel", "parry": "parry a scissor", "launch": "launch a rider (9 tiles)",
	"sling": "sling dash through regrowing gel", "catch_toss": "catch a parried scissor, toss it up",
}


static func hair_name(hair: int) -> String:
	return Player.HAIR_INFO[hair].name


## Every verb this pair of haircuts can perform together.
static func verbs(pair: Array) -> PackedStringArray:
	var out := PackedStringArray(UNIVERSAL)
	for hair in pair:
		for verb in SOLO[hair]:
			if verb not in out:
				out.append(verb)
	for combo in COMBOS:
		if combo.needs.all(func(h): return h in pair):
			out.append(combo.verb)
	return out


## The distinct unordered pairs a set of haircuts allows.
static func pairs(styles: PackedInt32Array) -> Array:
	var out := []
	for i in styles.size():
		for j in range(i + 1, styles.size()):
			out.append([styles[i], styles[j]])
	return out


## Gate names this pair can't get past (empty = the room is solvable for them).
static func blocked_gates(pair: Array, gates: Array) -> PackedStringArray:
	var can := verbs(pair)
	var out := PackedStringArray()
	for gate in gates:
		if not Array(gate.any).any(func(v): return v in can):
			out.append(gate.name)
	return out


## Tony's restyle: the next haircut in the room's set that the friend isn't wearing,
## or -1 when there's none (then the two friends swap instead).
static func next_style(current: int, partner: int, styles: PackedInt32Array) -> int:
	if styles.size() < 2 or current not in styles:
		return -1
	var at := styles.find(current)
	for step in range(1, styles.size()):
		var candidate := styles[(at + step) % styles.size()]
		if candidate != partner:
			return candidate
	return -1
