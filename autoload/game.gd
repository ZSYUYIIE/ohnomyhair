extends Node
## Level flow: checkpoints, shared respawn, restart (R), win, hit-stop.

signal won

var checkpoint := Vector2.ZERO
var has_won := false


func start_level(spawn: Vector2) -> void:
	checkpoint = spawn
	has_won = false
	Engine.time_scale = 1.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		restart()


func restart() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


## Both players go back to the checkpoint together (PLAN.md 1.4: no solo revive).
func respawn() -> void:
	for p in get_tree().get_nodes_in_group("players"):
		p.respawn(checkpoint + Vector2(-8.0 if p.player_id == 1 else 8.0, 0.0))


func win() -> void:
	if has_won:
		return
	has_won = true
	won.emit()


func hit_stop(duration: float) -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
