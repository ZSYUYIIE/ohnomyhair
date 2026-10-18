shader_type canvas_item;
varying vec4 vertex_tint;
void vertex() {
	vertex_tint = COLOR;
}
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (c.a < 48.0 / 255.0) { discard; }
	c.a = c.a > 200.0 / 255.0 ? 1.0 : clamp((c.a - 48.0 / 255.0) / (152.0 / 255.0), 0.0, 1.0);
	if (c.r > 150.0 / 255.0 && c.g < 90.0 / 255.0 && c.b < 110.0 / 255.0) {
		c.rgb = vec3(43.0, 33.0, 64.0) / 255.0;
	}
	COLOR = c * vertex_tint;
}
