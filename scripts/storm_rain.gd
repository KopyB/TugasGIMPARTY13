extends Control
## Thin, slanted rain is visually separate from the broad vertical foam texture.
var strength := 0.0
var weather_time := 0.0
var lightning := 0.0
var bolt_x := 1440.0

func _draw() -> void:
	if strength <= 0.001 and lightning <= 0.001:
		return
	draw_set_transform(Vector2.ZERO, 0.0, size / Vector2(1920, 1080))
	for index in range(96):
		var seed_value := float(index)
		var depth := 0.5 + fposmod(seed_value * 0.618034, 0.5)
		var speed := lerpf(920.0, 1450.0, depth)
		var start := Vector2(
			fposmod(seed_value * 317.17 - weather_time * speed * 0.48, 2240.0) - 160.0,
			fposmod(seed_value * 193.71 + weather_time * speed, 1400.0) - 160.0)
		var end := start + Vector2(-0.48, 1.0) * lerpf(35.0, 66.0, depth)
		# A faint dark edge keeps drops visible over white foam as well as blue water.
		draw_line(start, end, Color(0.08, 0.20, 0.32, 0.19 * strength), 4.2, true)
		draw_line(start, end, Color(0.77, 0.90, 1.0, lerpf(0.28, 0.55, depth) * strength), 1.7, true)
	if lightning > 0.001:
		for band in range(30):
			var fade := 0.25 + 0.75 * pow(1.0 - float(band) / 30.0, 2.0)
			draw_rect(Rect2(0, band * 36, 1920, 37), Color(0.70, 0.86, 1.0, fade * lightning * 0.22))
		var bolt := PackedVector2Array([Vector2(bolt_x, -10), Vector2(bolt_x - 52, 60),
			Vector2(bolt_x - 20, 85), Vector2(bolt_x - 90, 164), Vector2(bolt_x - 60, 182), Vector2(bolt_x - 130, 256)])
		draw_polyline(bolt, Color(0.43, 0.70, 1.0, lightning * 0.22), 13.0, true)
		draw_polyline(bolt, Color(0.88, 0.96, 1.0, lightning * 0.85), 2.5, true)
