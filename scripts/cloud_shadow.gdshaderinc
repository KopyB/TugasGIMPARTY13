// One world-space field for sea, hulls, creatures, obstacles and foam.
global uniform float rw_weather_time;
global uniform float rw_weather_strength;

float rw_cloud_shade(vec2 world) {
	float t = rw_weather_time * 1.65;
	float cloud = 0.5 + 0.25 * sin(world.x * 0.003 + world.y * 0.002 + t * 0.70)
		+ 0.25 * sin(world.x * 0.0017 - world.y * 0.004 - t * 0.51);
	return 1.0 - smoothstep(0.36, 0.77, cloud) * 0.26 * rw_weather_strength;
}
