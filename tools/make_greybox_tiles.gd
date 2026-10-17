extends SceneTree
## Writes the salon tile atlas: res://assets/tiles/greybox_tiles.png
## (0,0) = surface tile: checkered salon floor edge over wood paneling,
## (1,0) = interior tile: wood paneling, (2,0) = one-way platform: a wooden wall shelf.
## 32x32 each. Rerun the level builders afterwards so the tileset picks it up.
## Run: godot --headless --path . --script res://tools/make_greybox_tiles.gd


func _initialize() -> void:
	var img := Image.create_empty(96, 32, false, Image.FORMAT_RGBA8)
	_paneling(img, 0, Color("7a4e33"))
	_checker_edge(img, 0)
	_paneling(img, 32, Color("6b432c"))
	_shelf(img, 64)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/tiles"))
	var err := img.save_png("res://assets/tiles/greybox_tiles.png")
	print("greybox_tiles.png -> ", error_string(err))
	quit(err)


## Vertical wood planks with darker grooves.
func _paneling(img: Image, x0: int, wood: Color) -> void:
	img.fill_rect(Rect2i(x0, 0, 32, 32), wood)
	for x in [x0 + 7, x0 + 15, x0 + 23, x0 + 31]:
		img.fill_rect(Rect2i(x, 0, 1, 32), wood.darkened(0.25))
	img.fill_rect(Rect2i(x0, 31, 32, 1), wood.darkened(0.35))


## Black-and-white checkerboard strip on top (the classic barbershop floor), chrome trim below.
func _checker_edge(img: Image, x0: int) -> void:
	for cy in 2:
		for cx in 8:
			var dark := (cx + cy) % 2 == 0
			img.fill_rect(Rect2i(x0 + cx * 4, cy * 4, 4, 4), Color("26262b") if dark else Color("efeae2"))
	img.fill_rect(Rect2i(x0, 8, 32, 2), Color("c8ccd2"))


## Shelf plank on top (the 8px one-way lip), two chrome brackets under it, transparent below.
func _shelf(img: Image, x0: int) -> void:
	img.fill_rect(Rect2i(x0, 0, 32, 8), Color("b07a4f"))
	img.fill_rect(Rect2i(x0, 0, 32, 2), Color("d9a77a"))
	img.fill_rect(Rect2i(x0, 7, 32, 1), Color("6b432c"))
	for bx in [x0 + 4, x0 + 24]:
		for i in 6:
			img.fill_rect(Rect2i(bx, 8 + i, 6 - i, 1), Color("9aa0a6"))
