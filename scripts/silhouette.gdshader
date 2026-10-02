shader_type canvas_item;
render_mode unshaded;

uniform vec4 edge_color : source_color = vec4(0.92, 1.0, 0.97, 0.8);
uniform vec2 edge_pixels = vec2(2.0);
uniform vec2 motion_x = vec2(1.0, 0.0);
uniform vec2 motion_y = vec2(0.0, 1.0);
uniform vec2 motion_origin = vec2(0.0);

varying float item_alpha;

void vertex() {
	item_alpha = COLOR.a;
	VERTEX = mat2(motion_x, motion_y) * VERTEX + motion_origin;
}

void fragment() {
	vec2 d = TEXTURE_PIXEL_SIZE * edge_pixels;
	float center = texture(TEXTURE, UV).a;
	float rim = 0.0;
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			rim = max(rim, texture(TEXTURE, UV + vec2(float(x), float(y)) * d).a);
		}
	}
	COLOR = vec4(edge_color.rgb, max(0.0, rim - center) * edge_color.a * item_alpha);
}
