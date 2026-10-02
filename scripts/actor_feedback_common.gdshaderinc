#include "res://scripts/cloud_shadow.gdshaderinc"
varying vec2 cloud_world;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 0.95, 0.79, 1.0);
uniform float recoil_amount = 0.0;
uniform vec2 motion_x = vec2(1.0, 0.0);
uniform vec2 motion_y = vec2(0.0, 1.0);
uniform vec2 motion_origin = vec2(0.0, 0.0);

void vertex() {
	VERTEX.y += recoil_amount;
	VERTEX = mat2(motion_x, motion_y) * VERTEX + motion_origin;
	cloud_world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

vec4 rw_actor_color(vec4 original) {
	return vec4(mix(original.rgb * rw_cloud_shade(cloud_world), flash_color.rgb, flash_amount), original.a);
}
