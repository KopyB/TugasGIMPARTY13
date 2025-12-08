shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float strength : hint_range(0.0, 5.0) = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	
	uv.x += sin(uv.y * 10.0 + TIME * 5.0) * (strength * 0.01);
	uv.y += cos(uv.x * 10.0 + TIME * 5.0) * (strength * 0.01);
	
	vec4 screen_color = texture(SCREEN_TEXTURE, uv);
	vec3 final_color = mix(screen_color.rgb, vec3(0.5, 0.0, 0.5), strength * 0.2);
	
	COLOR = vec4(final_color, 1.0);
}