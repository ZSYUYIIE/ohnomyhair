extends SceneTree
## Builds one SpriteFrames per haircut from the strips made by tools/art/normalize_characters.py:
## res://assets/art/characters/<hair>/frames.tres. Rerun both after changing the sheets.
## Run: godot --headless --path . --script res://tools/build_character_frames.gd

const DIR := "res://assets/art/characters"


func _initialize() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR + "/frames.json"))
	var cell := Vector2(manifest.cell[0], manifest.cell[1])
	var err := OK
	for hair: String in manifest.characters:
		var frames := SpriteFrames.new()
		frames.remove_animation(&"default")
		var anims: Dictionary = manifest.characters[hair]
		for anim: String in anims:
			var info: Dictionary = anims[anim]
			var strip: Texture2D = load("%s/%s" % [DIR, info.file])
			frames.add_animation(anim)
			frames.set_animation_speed(anim, info.fps)
			frames.set_animation_loop(anim, info.loop)
			for i in int(info.frames):
				var atlas := AtlasTexture.new()
				atlas.atlas = strip
				atlas.region = Rect2(Vector2(i * cell.x, 0), cell)
				frames.add_frame(anim, atlas)
		var path := "%s/%s/frames.tres" % [DIR, hair]
		err = ResourceSaver.save(frames, path)
		print(path, " -> ", error_string(err))
		if err != OK:
			break
	quit(err)
