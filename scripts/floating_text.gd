extends Marker2D

@onready var label: Label = $Label

func start_animation(text_value: String, color: Color = Color.WHITE) -> void:
	var words := text_value.split(" ", true, 1)
	label.text = words[0]
	# Lighten reward tints enough that even dark purple rewards remain readable.
	label.modulate = color.lerp(Color(1.0, 0.98, 0.90), 0.82)
	if words.size() > 1:
		var caption := Label.new()
		caption.text = words[1].to_upper()
		caption.position = Vector2(-130, 22)
		caption.size = Vector2(260, 24)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caption.add_theme_font_override("font", preload("res://assets/norwester.otf"))
		caption.add_theme_font_size_override("font_size", 18)
		caption.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0))
		caption.add_theme_color_override("font_outline_color", Color(0.035, 0.08, 0.15))
		caption.add_theme_constant_override("outline_size", 4)
		add_child(caption)
	scale = Vector2.ONE * 0.94
	modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 48.0, 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.25).set_delay(0.60)
	tween.chain().tween_callback(queue_free)
