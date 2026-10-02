shader_type canvas_item;
render_mode unshaded;
#include "res://scripts/cloud_shadow.gdshaderinc"

uniform sampler2D water_texture : source_color, filter_linear, repeat_disable;
uniform vec2 world_x = vec2(1.0, 0.0);
uniform vec2 world_y = vec2(0.0, 1.0);
uniform vec2 world_origin = vec2(0.0);
uniform vec2 viewport_size = vec2(1920.0, 1080.0);
uniform vec2 source_size = vec2(1920.0, 1080.0);
uniform vec2 tile_size = vec2(1040.0, 1080.0);
uniform vec2 surface_offset = vec2(-143.0, -10.0);
uniform float scroll_y = 0.0;
uniform float motion_time = 0.0;
uniform float storm = 0.0;
uniform float storm_flash = 0.0;
uniform float wave_amplitude : hint_range(0.0, 24.0) = 10.0;
uniform float highlight_shimmer : hint_range(0.0, 1.0) = 0.40;
uniform float brightness : hint_range(0.5, 1.2) = 1.0;
uniform float contrast_softening : hint_range(0.0, 0.8) = 0.55;
uniform vec4 calm_color : source_color = vec4(0.478431, 0.937255, 1.0, 1.0);

void fragment() {
	vec2 world = mat2(world_x, world_y) * (UV * viewport_size) + world_origin;
	vec2 p = world - surface_offset - vec2(0.0, scroll_y);
	vec2 phase = p / tile_size * 6.28318530718;
	float t = motion_time * mix(1.0, 1.65, storm);
	// Integer spatial harmonics keep the distortion continuous at tile boundaries.
	vec2 swell = vec2(
		sin(phase.y * 2.0 + t * 0.62) + 0.45 * sin(phase.x * 2.0 + phase.y - t * 0.47),
		cos(phase.x + t * 0.52) + 0.40 * sin(phase.y * 3.0 - t * 0.30)
	);
	vec2 ripple = vec2(sin(phase.y * 7.0 - t * 0.90), cos(phase.x * 5.0 + t * 0.74));
	vec2 warped = p + wave_amplitude * mix(1.0, 1.6, storm) * (swell + ripple * 0.12);
	// The PNG contains an exact 1040px horizontal repeat inside its 1920px canvas.
	vec2 sample_uv = (mod(warped, tile_size) + vec2(0.5)) / source_size;
	vec4 water = texture(water_texture, sample_uv);
	float white_mask = smoothstep(0.76, 0.91, min(water.r, min(water.g, water.b)));
	float glint = 0.5 + 0.5 * sin(phase.x * 7.0 + phase.y * 4.0 + t * 1.3);
	// Lift dark patches toward the artwork's own sunlit cyan. Preserve foam whites.
	float luminance = dot(water.rgb, vec3(0.2126, 0.7152, 0.0722));
	float shadow_mask = 1.0 - smoothstep(0.60, 0.86, luminance);
	vec3 calmer = mix(water.rgb, calm_color.rgb, shadow_mask * contrast_softening) * brightness;
	// Only the existing white streaks shimmer; no extra texture or doubled outlines.
	calmer *= mix(1.0, 0.90 + 0.10 * glint, white_mask * highlight_shimmer);
	// The storm tint belongs to water; the moving cloud field is shared with actors.
	vec3 storm_water = mix(calmer, vec3(0.22, 0.47, 0.58), 0.48 * (1.0 - white_mask * 0.85));
	calmer = mix(calmer, storm_water, storm) * rw_cloud_shade(world);
	calmer += vec3(0.13, 0.18, 0.20) * storm_flash;
	COLOR = vec4(calmer, water.a);
}
