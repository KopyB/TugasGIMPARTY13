shader_type canvas_item;

uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform float brightness : hint_range(0.5, 1.2) = 1.0;
uniform float contrast_softening : hint_range(0.0, 0.8) = 0.55;
uniform vec4 calm_color : source_color = vec4(0.478431, 0.937255, 1.0, 1.0);

void fragment() {
	vec4 original = COLOR;
	// Lift dark patches toward the artwork's own sunlit cyan. Preserve foam whites.
	float luminance = dot(original.rgb, vec3(0.2126, 0.7152, 0.0722));
	float shadow_mask = 1.0 - smoothstep(0.60, 0.86, luminance);
	vec3 calmer = mix(original.rgb, calm_color.rgb, shadow_mask * contrast_softening) * brightness;
	COLOR = vec4(mix(original.rgb, calmer, strength), original.a);
}
