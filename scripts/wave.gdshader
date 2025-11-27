shader_type canvas_item;

uniform float wave_strength = 5.0;
uniform float wave_speed = 2.0;	
uniform float wave_frequency = 10.0;
uniform bool paused = false;
uniform float time_scale = 1.0;

void fragment() {
	float t = TIME * time_scale;
    vec2 uv = UV;

    // Time-based vertical wave
    uv.y += sin(uv.x * wave_frequency + TIME * wave_speed) * (wave_strength / 100.0);

    COLOR = texture(TEXTURE, uv);
}
