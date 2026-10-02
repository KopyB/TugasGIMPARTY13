extends Node2D
## Oil on the water marks the actual blast radius before the barrel detonates.
var radius := 257.0
var elapsed := 0.0
var fuse_duration := 0.0

func _ready() -> void:
	z_index = -4

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	var urgency := 0.0
	if fuse_duration > 0.0:
		urgency = clampf(elapsed / fuse_duration, 0.0, 1.0)
	var pulse := (0.5 + 0.5 * sin(elapsed * lerpf(5.0, 16.0, urgency))) * urgency
	# The outer circle is exact. Irregular inner contours supply the oil texture.
	draw_circle(Vector2.ZERO, radius, Color(0.10, 0.13, 0.22, 0.15 + pulse * 0.025))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 96, Color(0.30, 0.22, 0.35, 0.34), 2.0, true)
	for layer_index in range(3):
		var contour := PackedVector2Array()
		for index in range(73):
			var angle := float(index) / 72.0 * TAU
			var ripple := 0.035 * sin(angle * 5.0 + elapsed * 0.8 + layer_index)
			ripple += 0.02 * cos(angle * 9.0 - elapsed * 0.45)
			var distance := radius * (0.83 - float(layer_index) * 0.16 + ripple)
			contour.append(Vector2.from_angle(angle) * distance)
		var sheen := Color(0.37, 0.27, 0.52, 0.18) if layer_index % 2 == 0 else Color(0.35, 0.59, 0.51, 0.16)
		draw_polyline(contour, sheen, 8.0 - layer_index * 2.0, true)
	if fuse_duration > 0.0:
		# A warm ripple near the barrel identifies its live fuse, not a moving engine.
		draw_arc(Vector2.ZERO, 47.0 + pulse * 5.0, 0, TAU, 40, Color(1.0, 0.62, 0.22, 0.30 + pulse * 0.45), 2.5, true)
