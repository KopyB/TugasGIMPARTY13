extends Node2D

const PACING = preload("res://scripts/voyage_pacing.gd")

var strength: float = 1.0
var drift_speed := -1.0
var elapsed: float = 0.0
const DURATION: float = 0.65

func _ready() -> void:
	z_index = 2
	if drift_speed < 0.0:
		drift_speed = PACING.current_speed(GameData.is_hard_mode)

func _process(delta: float) -> void:
	elapsed += delta
	# Drift at the same speed as the scrolling sea.
	position.y += drift_speed * delta
	queue_redraw()
	if elapsed >= DURATION:
		queue_free()

func _draw() -> void:
	var progress := clampf(elapsed / DURATION, 0.0, 1.0)
	var radius := lerpf(13.0, 36.0, progress) * strength
	var foam := Color(0.86, 0.99, 1.0, 0.25 * (1.0 - progress))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.6))
	draw_arc(Vector2.ZERO, radius, PI * 0.12, PI * 0.88, 12, foam, 2.5, true)
