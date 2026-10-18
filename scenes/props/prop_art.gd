class_name PropArt
## Hand-drawn prop textures (tools/art/make_l1_art.py) for props that come in any size:
## each is a nine-slice, so the inked border keeps its width and the middle tiles.

static var _styles := {}


static func gloss(canvas: CanvasItem, area: Rect2, color: Color, radius := 10) -> void:
	var skin := UiTheme.card(color, UiTheme.INK, 3, radius, 0)
	skin.shadow_size = 2
	skin.shadow_color = Color(0.15, 0.06, 0.22, 0.28)
	skin.shadow_offset = Vector2(2, 4)
	canvas.draw_style_box(skin, area)
	var shine := UiTheme.card(color.lightened(0.35), Color.TRANSPARENT, 0, maxi(radius - 4, 2), 0)
	canvas.draw_style_box(shine, Rect2(area.position + Vector2(5, 4), Vector2(maxf(area.size.x - 10, 2), minf(area.size.y * 0.19, 8))))


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
