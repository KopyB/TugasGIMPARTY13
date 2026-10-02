shader_type canvas_item;
render_mode unshaded;

uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform float rim_texels = 14.0;
uniform vec4 rim_color : source_color = vec4(1.0, 0.96, 0.78, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 0.36, 0.63, 1.0);
varying vec4 sprite_tint;

void vertex() {
	sprite_tint = COLOR;
}

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	vec2 step_uv = TEXTURE_PIXEL_SIZE * rim_texels;
	float nearby = 0.0;
	nearby = max(nearby, texture(TEXTURE, UV + vec2(step_uv.x, 0.0)).a);
	nearby = max(nearby, texture(TEXTURE, UV - vec2(step_uv.x, 0.0)).a);
	nearby = max(nearby, texture(TEXTURE, UV + vec2(0.0, step_uv.y)).a);
	nearby = max(nearby, texture(TEXTURE, UV - vec2(0.0, step_uv.y)).a);
	nearby = max(nearby, texture(TEXTURE, UV + step_uv * 0.7071).a);
	nearby = max(nearby, texture(TEXTURE, UV - step_uv * 0.7071).a);
	nearby = max(nearby, texture(TEXTURE, UV + vec2(step_uv.x, -step_uv.y) * 0.7071).a);
	nearby = max(nearby, texture(TEXTURE, UV + vec2(-step_uv.x, step_uv.y) * 0.7071).a);
	float body_mask = smoothstep(0.16, 0.52, max(original.r, max(original.g, original.b)));
	vec3 body = mix(original.rgb, core_color.rgb, body_mask * 0.42 * strength);
	float rim = nearby * (1.0 - original.a) * strength;
	float alpha = original.a + rim;
	vec3 rgb = (body * original.a + rim_color.rgb * rim) / max(alpha, 0.00001);
	COLOR = vec4(rgb, alpha) * sprite_tint;
}
