extends RefCounted
## Recover the complete pull poses from the existing sheet. The old 181px grid
## cuts off tails spanning a cell boundary; these measured regions follow each
## whole figure. No new character art or collision changes are involved.
const SCALE := 0.45
const SHEET := preload("res://assets/art/characters/twin_tails/pull_source.png")
const MATERIAL := preload("res://assets/art/characters/twin_tails/pull_cleanup.tres")
const REGIONS := [
	Rect2(34, 1104, 118, 131), Rect2(190, 1102, 198, 134),
	Rect2(390, 1102, 182, 134), Rect2(572, 1100, 159, 137),
	Rect2(753, 1106, 175, 130), Rect2(934, 1102, 122, 134),
]
const ANCHORS := [Vector2(100.96, 1230), Vector2(268.06, 1231),
	Vector2(458.31, 1231), Vector2(641.19, 1232),
	Vector2(821.72, 1231), Vector2(1004.10, 1231)]
static var _frames: SpriteFrames

static func get_frames() -> SpriteFrames:
	if _frames: return _frames
	_frames = (preload("res://assets/art/characters/twin_tails/frames.tres") as SpriteFrames).duplicate()
	_frames.clear(&"pull")
	for i in REGIONS.size():
		var texture := AtlasTexture.new()
		texture.atlas = SHEET
		texture.region = REGIONS[i]
		texture.margin = Rect2(Vector2(68, 104) / SCALE - ANCHORS[i] + REGIONS[i].position,
			Vector2(136, 128) / SCALE - REGIONS[i].size)
		_frames.add_frame(&"pull", texture)
	return _frames
