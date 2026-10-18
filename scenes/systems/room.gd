class_name Room
extends Node2D
## One single-screen room. Position is its top-left corner (rooms are SIZE apart).
## Needs children: SpawnP1, SpawnP2 (Marker2D) and Exit (RoomExit).

const SIZE := Vector2(1280, 720)

@export var title := ""
## The pair (P1, P2) both friends wear when this room starts or restarts.
## Empty = keep whatever they wear.
@export var starting_hair := PackedInt32Array()
## The only haircuts the assistant's scissors can restyle into.
## Every distinct pair from this set must pass every gate (tests/test_gates.gd).
@export var styles := PackedInt32Array()
## The room's obstacles for the gate check: {"name": String, "any": PackedStringArray},
## each passable with any one of the verbs in StyleRules.
@export var gates: Array[Dictionary] = []

@onready var exit: RoomExit = $Exit


func spawn_point(player_id: int) -> Vector2:
	return (get_node("SpawnP%d" % player_id) as Marker2D).global_position
