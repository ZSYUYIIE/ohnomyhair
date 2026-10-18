extends RefCounted
## Hand-authored flat vector puppet. All poses share the same feet origin and
## head-knob anchor; animation never moves the boss's physics or stomp target.
const INK := Color("2b2140")
const RED := Color("df6b72")
const DARK_RED := Color("bb5666")
const METAL := Color("b8b5c7")
const BLADE := Color("e8e5ee")
const GOLD := Color("f1c44f")
const PURPLE := Color("786378")

static func paint(c: Node2D, pose: StringName, time: float, age: float, facing: float, moving: bool, furious: bool, distance := 0.0) -> void:
	var running := pose == &"charge"
	var gait := distance / (100.0 if running else 60.0)
	var stride := sin(gait * TAU) if moving and pose in [&"walk", &"charge"] else 0.0
	var bob := -absf(stride) * 2.0
	var lean := 0.0
	if pose == &"windup":
		lean = -0.09 - sin(time * 30.0) * 0.025
		bob = 3.0
	elif pose == &"dazed":
		lean = sin(time * 5.0) * 0.045
	elif pose == &"hurt":
		lean = -sin(minf(age / 0.8, 1.0) * PI) * 0.18
	elif pose == &"dead":
		lean = minf(age * 2.0, 1.0) * 0.55

	# A run changes the limb cadence, not the torso, head height or body angle.
	var body_scale := Vector2(facing, 1.0)
	var hip := Vector2(0, -37) * body_scale
	var body_origin := Vector2(0, bob) + hip - hip.rotated(lean)
	var body_transform := Transform2D(lean, body_scale, 0.0, body_origin)
	# Longer strides and lifted boots convey speed while the body stays upright.
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))
	for side in [-1.0, 1.0]:
		var step := fposmod(gait + (0.5 if side < 0 else 0.0), 1.0)
		var swing := clampf((step - 0.6) / 0.4, 0, 1)
		var reach := 30.0 if running else 18.0
		var travel := lerpf(reach, -reach, step / 0.6) if step < 0.6 else lerpf(-reach, reach, swing)
		var lift := sin(swing * PI) * (16 if running else 10)
		var foot := Vector2(side * 17.0 + (travel if moving else 0.0), -7.0 - (lift if moving else 0.0))
		var hip_at := (body_transform * Vector2(side * 20.0, -40.0)) * Vector2(facing, 1)
		_rod(c, hip_at, foot + Vector2(0, -5), 8)
		_panel(c, Rect2(foot + Vector2(-14, -5), Vector2(28, 12)), RED, 5)
	c.draw_set_transform(body_origin, lean, body_scale)
	# Scissor hands swing from the shoulders instead of sliding a single PNG.
	for side in [-1.0, 1.0]:
		var shoulder := Vector2(side * 32, -77)
		var elbow := Vector2(side * 46, -65 + stride * side * 4)
		var hand := Vector2(side * 56, -91 + stride * side * 7)
		var angle: float = side * -0.24
		var opening := 0.30
		match pose:
			&"shoot":
				if side > 0:
					elbow = Vector2(48, -48)
					hand = Vector2(62, -30)
					angle = PI / 2.0
					opening = 0.12 + 0.30 * absf(sin(age * 12.5))
			&"windup", &"rain":
				hand = Vector2(side * 46, -108)
				opening = 0.58
			&"charge":
				elbow = Vector2(side * 45, -64 + stride * side * 5)
				hand = Vector2(side * 56, -70 + stride * side * 8)
				angle = side * PI / 2.0
				opening = 0.12
			&"dazed", &"hurt", &"dead":
				hand = Vector2(side * 54, -44)
				angle = side * 2.3
				opening = 0.16
		_rod(c, shoulder, elbow, 8)
		_rod(c, elbow, hand, 7)
		_disc(c, elbow, 6, PURPLE)
		_scissors(c, hand, angle, opening)
	_panel(c, Rect2(-34, -88, 68, 51), RED, 7)
	# A single darker side panel, like the small clipper bots and the coral chair.
	c.draw_line(Vector2(26, -82), Vector2(26, -44), DARK_RED, 5, true)
	_panel(c, Rect2(-25, -114, 50, 27), PURPLE, 7)
	var eye := Vector2(0, -101)
	_disc(c, eye, 9, GOLD)
	if pose in [&"dazed", &"hurt", &"dead"]:
		c.draw_line(Vector2(-4, -105), Vector2(4, -97), INK, 2.5, true)
		c.draw_line(Vector2(4, -105), Vector2(-4, -97), INK, 2.5, true)
	else:
		c.draw_line(eye + Vector2(2 if furious else 0, -5), eye + Vector2(-1, 4), INK, 3, true)
	# The real stomp target is centered at y=-128. Keep the visible knob there.
	var knob := Vector2(0, -128)
	_rod(c, knob + Vector2(0, 12), knob + Vector2(0, 2), 5)
	_disc(c, knob, 8, GOLD if pose == &"dazed" else RED)
	c.draw_set_transform(Vector2.ZERO)
	if pose == &"dazed":
		for i in 3:
			var a := time * 3.0 + i * TAU / 3.0
			var center := Vector2(cos(a) * 23, -143 + sin(a) * 5)
			c.draw_line(center - Vector2(3, 0), center + Vector2(3, 0), GOLD, 2.5, true)
			c.draw_line(center - Vector2(0, 3), center + Vector2(0, 3), GOLD, 2.5, true)
	if pose == &"charge":
		for i in 3:
			var at := Vector2(-facing * (58 + i * 7), -25 - i * 10)
			c.draw_line(at, at + Vector2(-facing * 12, 0), INK, 2, true)

static func _panel(c: Node2D, rect: Rect2, color: Color, radius: int) -> void:
	var skin := StyleBoxFlat.new()
	skin.bg_color = color
	skin.border_color = INK
	skin.set_border_width_all(3)
	skin.set_corner_radius_all(radius)
	skin.corner_detail = 5
	c.draw_style_box(skin, rect)

static func _disc(c: Node2D, at: Vector2, radius: float, color: Color) -> void:
	c.draw_circle(at, radius + 1.5, INK, true, -1, true)
	c.draw_circle(at, radius - 1.5, color, true, -1, true)

static func _rod(c: Node2D, a: Vector2, b: Vector2, width: float) -> void:
	c.draw_line(a, b, INK, width + 3, true)
	c.draw_line(a, b, METAL, width - 3, true)

static func _scissors(c: Node2D, at: Vector2, angle: float, opening: float) -> void:
	for side in [-1.0, 1.0]:
		var turn := Transform2D(angle + opening * side, at)
		var blade := turn * PackedVector2Array([Vector2(-2, 1), Vector2(-3, -23), Vector2(1, -28), Vector2(5, -5)])
		c.draw_colored_polygon(blade, BLADE)
		c.draw_polyline(PackedVector2Array([blade[0], blade[1], blade[2], blade[3], blade[0]]), INK, 2, true)
	_disc(c, at, 6, METAL)
