shader_type canvas_item;
render_mode unshaded;

uniform float weather_time = 0.0;
uniform float strength = 0.0;
uniform float lightning = 0.0;
uniform vec2 viewport_size = vec2(1920.0, 1080.0);

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float rain(vec2 pixel, float scale, float speed) {
	vec2 p = pixel * scale;
	p.x += p.y * 0.28;
	p.y -= weather_time * speed;
	vec2 cell = floor(p / vec2(58.0, 155.0));
	vec2 local = mod(p, vec2(58.0, 155.0));
	float seed = hash21(cell);
	float streak = 1.0 - smoothstep(0.4, 1.4, abs(local.x - 8.0 - seed * 42.0));
	streak *= smoothstep(12.0, 18.0, local.y) * (1.0 - smoothstep(35.0, 45.0, local.y));
	return streak * step(0.4, seed);
}

void fragment() {
	vec2 pixel = UV * viewport_size;
	float drops = rain(pixel, 1.0, 1080.0) * 0.22 + rain(pixel, 0.65, 760.0) * 0.11;
	// Upper-edge lightning avoids a full-screen white flash and leaves HUD above us.
	float sky = (1.0 - smoothstep(0.0, 0.7, UV.y)) * lightning * 0.28;
	float edge = smoothstep(0.32, 0.72, abs(UV.x - 0.5));
	float mist = edge * 0.035;
	COLOR = vec4(vec3(0.71, 0.86, 0.96), clamp((drops + sky + mist) * strength, 0.0, 0.32));
}
