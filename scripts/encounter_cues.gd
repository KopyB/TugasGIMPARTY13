extends Node2D
## Draws from live collision shapes and attack state, with no gameplay changes.

var actor
var effects
var cast_elapsed: float = 10.0

func _ready() -> void:
	actor = get_parent()
	effects = get_node("/root/VisualFX")
	z_index = 1

func cast() -> void:
	cast_elapsed = 0.0

func _process(delta: float) -> void:
	cast_elapsed += delta
	queue_redraw()

func _draw() -> void:
	if not effects.enabled or actor.is_game_over:
		return
	if actor.enemy_type == 4:
		_draw_shark()
	elif cast_elapsed < 0.8:
		for index in range(2):
			var phase := clampf((cast_elapsed - float(index) * 0.16) / 0.64, 0.0, 1.0)
			if phase > 0.0 and phase < 1.0:
				draw_arc(Vector2.ZERO, lerpf(24, 110, phase), 0, TAU, 64, Color(1, 0.64, 0.93, (1.0 - phase) * 0.8), 3.0, true)

func _draw_shark() -> void:
	if actor.is_paralyzed:
		return
	var collider: CollisionShape2D = actor.collision_shape_2d
	if collider == null or not collider.shape is RectangleShape2D:
		return
	var half: Vector2 = collider.shape.size * 0.5
	var top: float = collider.position.y - half.y
	var bottom: float = collider.position.y + half.y
	if actor.charge_warning_active:
		var length := 2600.0
		draw_rect(Rect2(Vector2(collider.position.x - half.x, top), Vector2(length, half.y * 2.0)), Color(0.85, 0.12, 0.27, 0.16))
		for y in [top, bottom]:
			draw_line(Vector2(0, y), Vector2(length, y), Color(0.3, 0.06, 0.16, 0.65), 4.0, true)
			draw_line(Vector2(0, y), Vector2(length, y), Color(1, 0.47, 0.53, 0.9), 2.0, true)
		var sprite: AnimatedSprite2D = actor.torpedoshark
		var count: int = sprite.sprite_frames.get_frame_count(sprite.animation)
		var progress := clampf((float(sprite.frame) + sprite.frame_progress) / maxf(count, 1), 0, 1)
		if sprite.animation != &"transition":
			progress = 0.0
		draw_arc(Vector2.ZERO, 48, -PI / 2, -PI / 2 + TAU * maxf(progress, 0.01), 48, Color(1, 0.91, 0.76, 0.95), 3, true)
	elif actor.is_shark_charging and actor.shark_charge_direction != Vector2.ZERO:
		for side in [-1.0, 1.0]:
			draw_line(Vector2(-40, side * 12), Vector2(-112, side * 23), Color(0.93, 1, 1, 0.72), 3, true)
			draw_line(Vector2(-112, side * 23), Vector2(-154, side * 27), Color(0.93, 1, 1, 0.22), 2, true)
