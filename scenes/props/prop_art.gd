class_name PropArt
## Hand-drawn prop textures (tools/art/make_l1_art.py) for props that come in any size:
## each is a nine-slice, so the inked border keeps its width and the middle tiles.

static var _styles := {}


## A cached StyleBoxTexture for `path`; `margin` px at each edge never stretch.
static func nine_slice(path: String, margin: float) -> StyleBoxTexture:
	if not _styles.has(path):
		var sb := StyleBoxTexture.new()
		sb.texture = load(path)
		sb.set_texture_margin_all(margin)
		sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		_styles[path] = sb
	return _styles[path]
