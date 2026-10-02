extends Sprite2D
## Mirrors an existing sprite's art and visual transform. Never adds a hitbox.

var source
var width: float = 1.8
var only_near_blasts: bool = false
var effects
var rim: ShaderMaterial

func _ready() -> void:
	effects = get_node("/root/VisualFX")
	z_as_relative = false
	z_index = 35
	process_priority = 10
	rim = ShaderMaterial.new()
	rim.shader = preload("res://scripts/silhouette.gdshader")
	material = rim

func _process(_delta: float) -> void:
	if not is_instance_valid(source):
		queue_free()
		return
	visible = effects.enabled and source.is_visible_in_tree()
	if only_near_blasts and visible:
		visible = false
		for blast in get_tree().get_nodes_in_group("rw_visible_blasts"):
			if source.global_position.distance_squared_to(blast.global_position) < 160000.0:
				visible = true
				break
	if not visible:
		return
	transform = source.transform
	if source is AnimatedSprite2D:
		texture = source.sprite_frames.get_frame_texture(source.animation, source.frame)
	elif source is Sprite2D:
		texture = source.texture
	flip_h = source.flip_h
	flip_v = source.flip_v
	centered = source.centered
	offset = source.offset
	rim.set_shader_parameter("edge_pixels", Vector2(width / maxf(absf(global_scale.x), 0.01), width / maxf(absf(global_scale.y), 0.01)))
	if source.material is ShaderMaterial:
		for parameter in ["motion_x", "motion_y", "motion_origin"]:
			var value = source.material.get_shader_parameter(parameter)
			if value != null:
				rim.set_shader_parameter(parameter, value)
