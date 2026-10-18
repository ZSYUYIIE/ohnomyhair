shader_type canvas_item;
// The generated transparent cutout has a faint alpha halo outside its sticker rim.
// Keep the opaque original shapes while dropping that halo at game scale.
void fragment() {
	vec4 cutout = texture(TEXTURE, UV);
	cutout.a = smoothstep(0.80, 0.95, cutout.a);
	COLOR = cutout;
}
