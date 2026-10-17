class_name Room
extends Node2D
## One single-screen room. Position is its top-left corner (rooms are SIZE apart).
## Needs children: SpawnP1, SpawnP2 (Marker2D) and Exit (RoomExit).

const SIZE := Vector2(1280, 720)

@export var title := ""

@onready var exit: RoomExit = $Exit


func spawn_point(player_id: int) -> Vector2:
	return (get_node("SpawnP%d" % player_id) as Marker2D).global_position
