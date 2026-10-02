extends Node2D
## One reusable cue per target, so multishot and lasers cannot stack badges.
var actor: Node2D
var source_pulse := false
var elapsed := 1.0
var parrot_icon: Texture2D
var caption: Label

func _ready() -> void:
	actor = get_parent() as Node2D
	top_level = true
	transform = Transform2D.IDENTITY
	z_as_relative = false
	z_index = 36
	if not source_pulse:
		caption = Label.new()
		caption.text = "PARROT GUARD"
		caption.position = Vector2(-55, -84)
		caption.size = Vector2(138, 24)
		caption.add_theme_font_override("font", preload("res://assets/norwester.otf"))
		caption.add_theme_font_size_override("font_size", 18)
		caption.add_theme_color_override("font_color", Color(1, 0.94, 0.98))
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(caption)
	visible = false

func trigger(icon: Texture2D = null) -> void:
	# Sustained fire holds one cue on screen without restarting its first frame.
	if elapsed >= 0.5:
		elapsed = 0.0
	else:
		elapsed = minf(elapsed, 0.2)
	parrot_icon = icon
	global_position = actor.global_position
	visible = true
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	visible = elapsed < 0.5 and actor.is_visible_in_tree()
	if not visible:
		return
	global_position = actor.global_position
	modulate = Color(1, 1, 1, 1.0 - smoothstep(0.25, 0.5, elapsed))
	queue_redraw()

func _draw() -> void:
	if source_pulse:
		draw_arc(Vector2.ZERO, 38 + elapsed * 32, 0, TAU, 48, Color(1, 0.63, 0.86, 0.85), 3, true)
		return
	var shield := PackedVector2Array([Vector2(-24, -30), Vector2(0, -38), Vector2(24, -30), Vector2(20, 8), Vector2(0, 26), Vector2(-20, 8)])
	draw_colored_polygon(shield, Color(0.66, 0.22, 0.51, 0.28))
	var border := shield.duplicate()
	border.append(shield[0])
	draw_polyline(border, Color(0.24, 0.1, 0.26, 0.95), 6, true)
	draw_polyline(border, Color(1, 0.71, 0.89), 3, true)
	draw_rect(Rect2(-88, -85, 176, 26), Color(0.18, 0.09, 0.23, 0.96))
	if parrot_icon != null:
		draw_texture_rect(parrot_icon, Rect2(-86, -85, 28, 26), false)
