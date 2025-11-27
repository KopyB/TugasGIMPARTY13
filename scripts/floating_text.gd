extends Marker2D

@onready var label: Label = $Label

func start_animation(text_value: String, color: Color = Color.WHITE):
	label.text = text_value
	label.modulate = color
	
	scale = Vector2(0.5, 0.5) 
	modulate.a = 0.0          
	
	var tween = create_tween()
	
	tween.set_parallel(true)
	
	# Float Up 
	tween.tween_property(self, "position:y", position.y - 80, 1.0).set_ease(Tween.EASE_OUT)
	
	# Fade In (Muncul)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	
	# Scale Up (Pop effect)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_BOUNCE)
	tween.set_parallel(false)
	tween.tween_interval(0.3)
	
	# Fade Out (Menghilang)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	
	tween.tween_callback(queue_free)
