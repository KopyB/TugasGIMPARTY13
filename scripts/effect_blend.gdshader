shader_type canvas_item;
render_mode unshaded;
#include "res://scripts/cloud_shadow.gdshaderinc"
uniform float cloud_receiver = 0.0;
varying vec2 cloud_world;

uniform sampler2D next_frame : source_color, filter_linear, repeat_disable;
uniform float frame_mix : hint_range(0.0, 1.0) = 0.0;
uniform float art_scale = 1.0;
uniform vec2 art_shift = vec2(0.0);
uniform float art_opacity = 1.0;
uniform float outer_fade = 0.0;
varying vec4 sprite_tint;

void vertex() {
	sprite_tint = COLOR;
	VERTEX = VERTEX * art_scale + art_shift;
	cloud_world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 a = texture(TEXTURE, UV);
	vec4 b = texture(next_frame, UV);
	// Blend premultiplied samples to avoid dark fringes around transparent foam.
	vec4 mixed = mix(vec4(a.rgb * a.a, a.a), vec4(b.rgb * b.a, b.a), frame_mix);
	vec3 rgb = mixed.rgb / max(mixed.a, 0.00001);
	float outer_mask = smoothstep(0.18, 0.50, length(UV - vec2(0.5)));
	float fade = 1.0 - outer_mask * outer_fade;
	rgb *= mix(1.0, rw_cloud_shade(cloud_world), cloud_receiver);
	COLOR = vec4(rgb, mixed.a * art_opacity * fade) * sprite_tint;
}
