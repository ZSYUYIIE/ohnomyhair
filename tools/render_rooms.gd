extends SceneTree
## Renders every room of every level to PNG, for reviewing layouts without playing.
## Needs a real window (not --headless). Output: $SHOTS_DIR, or user://shots.
## Run: godot --path . --script res://tools/render_rooms.gd
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var out := OS.get_environment("SHOTS_DIR")
	if out == "":
		out = ProjectSettings.globalize_path("user://shots")
	DirAccess.make_dir_recursive_absolute(out)
	for n in [1, 2, 3]:
		var scene: PackedScene = load("res://scenes/levels/level_0%d.tscn" % n)
		var probe: Level = scene.instantiate()
		var count: int = probe.get_node("Rooms").get_child_count()
		probe.free()
		for r in count:
			var lvl: Level = scene.instantiate()
			lvl.start_room = r
			root.add_child(lvl)
			for i in 30: await process_frame
			lvl.banner.modulate.a = 0.0
			for i in 3: await process_frame
			root.get_viewport().get_texture().get_image().save_png("%s/L%d_R%d.png" % [out, n, r + 1])
			lvl.queue_free()
			for i in 3: await process_frame
	quit()
