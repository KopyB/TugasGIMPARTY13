shader_type canvas_item;
#include "res://scripts/actor_feedback_common.gdshaderinc"

uniform vec2 normal_center = vec2(0.5);
uniform vec2 normal_radius = vec2(0.5);
uniform int normal_kind = 1;
uniform float normal_strength : hint_range(0.0, 1.0) = 0.65;

void fragment() {
	vec4 original = COLOR;
	COLOR = rw_actor_color(original);
	vec2 p = (UV - normal_center) / max(normal_radius, vec2(0.001));
	// Smooth slopes describe large volumes, not paint strokes or outlines.
	float mask = 1.0 - smoothstep(0.90, 1.18, length(p));
	vec2 slope = vec2(p.x * 0.70, p.y * 0.24);
	if (normal_kind == 2) {
		// Cannon tube runs along Y. Keep the end cap gently rounded.
		mask = (1.0 - smoothstep(0.90, 1.12, abs(p.x)))
			* (1.0 - smoothstep(0.90, 1.12, abs(p.y)));
		slope = vec2(p.x * 1.05, p.y * 0.20);
	} else if (normal_kind == 3) {
		slope = vec2(p.x * 0.85, p.y * 0.32);
		// The barrel PNG includes painted foam. Leave that foam flat.
		float foam = smoothstep(0.82, 0.94, min(original.r, min(original.g, original.b)));
		mask *= 1.0 - foam;
	}
	vec3 mapped = normalize(vec3(slope.x, -slope.y, 1.0));
	NORMAL_MAP = mapped * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = normal_strength * mask;
}

void light() {
	// Normalize against a flat surface at the same light height. This preserves
	// the bright painted base, and makes a flat normal reproduce R9 lighting.
	float flat_response = max(LIGHT_DIRECTION.z, 0.35);
	float shaped_response = max(dot(NORMAL, LIGHT_DIRECTION), 0.0);
	float response = clamp(1.0 + (shaped_response - LIGHT_DIRECTION.z) / flat_response, 0.45, 1.45);
	LIGHT = vec4(COLOR.rgb * LIGHT_COLOR.rgb * LIGHT_ENERGY * response, LIGHT_COLOR.a);
}
