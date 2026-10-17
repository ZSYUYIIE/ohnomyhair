extends SceneTree
## Writes the placeholder tile atlas: res://assets/tiles/greybox_tiles.png
## (0,0) = surface tile, (1,0) = interior tile. 32x32 each.
## Run: godot --headless --path . --script res://tools/make_greybox_tiles.gd


func _initialize() -> void:
	var img := Image.create_empty(64, 32, false, Image.FORMAT_RGBA8)
	_paint_tile(img, 0, Color("6b7080"), Color("a3a9b8"))
	_paint_tile(img, 32, Color("4f5361"), Color("4f5361"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/tiles"))
	var err := img.save_png("res://assets/tiles/greybox_tiles.png")
	print("greybox_tiles.png -> ", error_string(err))
	quit(err)


func _paint_tile(img: Image, x0: int, base: Color, top: Color) -> void:
	img.fill_rect(Rect2i(x0, 0, 32, 32), base.darkened(0.25))
	img.fill_rect(Rect2i(x0 + 1, 1, 30, 30), base)
	img.fill_rect(Rect2i(x0 + 1, 1, 30, 4), top)
