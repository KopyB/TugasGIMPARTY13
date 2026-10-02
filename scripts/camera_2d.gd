extends Camera2D
## Stable arena framing. Ship steering never drags the playfield sideways.
const ARENA = preload("res://scripts/arena_geometry.gd")
var arena_zoom := Vector2.ONE

func _ready() -> void:
	position_smoothing_enabled = false
	drag_horizontal_enabled = false
	drag_vertical_enabled = false
	ignore_rotation = true
	limit_left = 0
	limit_top = 0
	limit_right = int(ARENA.SIZE.x)
	limit_bottom = int(ARENA.SIZE.y)
	global_position = ARENA.SIZE * 0.5
	cameraeffects.register_camera(self)
	cameraeffects.register_overlay(get_node_or_null("darken/darkencolor") as ColorRect)
	get_viewport().size_changed.connect(_fit_arena)
	_fit_arena()

func _fit_arena() -> void:
	# Project stretch keeps the 16:9 design aspect, including ultrawide windows.
	arena_zoom = get_viewport_rect().size / ARENA.SIZE
	zoom = arena_zoom
	offset = Vector2.ZERO
	force_update_scroll()

func clamp_shake_offset(requested: Vector2) -> Vector2:
	var half_view := get_viewport_rect().size / zoom * 0.5
	var minimum := half_view - global_position
	var maximum := ARENA.SIZE - half_view - global_position
	# Clamp against the temporarily overscanned view during an impulse.
	return requested.clamp(minimum, maximum)

func apply_shake(requested: Vector2, strength: float) -> void:
	# At most 1.8% temporary overscan provides room for the impulse without
	# revealing space outside the arena. Full framing returns with the envelope.
	zoom = arena_zoom * (1.0 + 0.018 * clampf(strength / 7.5, 0.0, 1.0))
	offset = clamp_shake_offset(requested)
	force_update_scroll()
