extends CanvasLayer

@onready var dizzy_rect: ColorRect = $DizzyEffect

var active_tween: Tween 

func _ready():
	add_to_group("visual_effect_manager")
	layer = 1
	dizzy_rect.hide()
	
	if dizzy_rect.material:
		dizzy_rect.material.set_shader_parameter("strength", 0.0)

func trigger_siren_blindness(duration: float):
	dizzy_rect.show()
	# kill overwrite tween
	if active_tween:
		active_tween.kill()
	
	# new tween
	active_tween = create_tween()
	
	# strength please
	var current_strength = 0.0
	if dizzy_rect.material:
		current_strength = dizzy_rect.material.get_shader_parameter("strength")
	var target_strength = 0.8 
	# Fade in
	active_tween.tween_method(set_shader_strength, current_strength, target_strength, 0.5)
	# hold
	active_tween.tween_interval(duration)
	# fade outt
	active_tween.tween_method(set_shader_strength, target_strength, 0.0, 0.5)
	active_tween.tween_callback(dizzy_rect.hide)
	active_tween.tween_callback(func(): active_tween = null)

func set_shader_strength(value: float):
	if dizzy_rect.material:
		dizzy_rect.material.set_shader_parameter("strength", value)
