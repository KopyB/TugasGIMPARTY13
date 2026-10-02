extends Node
## Blend visual frames while leaving AnimatedSprite2D timing and signals intact.

const BLEND_SHADER = preload("res://scripts/effect_blend.gdshader")
var style: String = "foam"
var sprite: AnimatedSprite2D
var effects
var blend_material: ShaderMaterial
var elapsed: float = 0.0
var cached_animation: StringName = &""
var cached_frames: SpriteFrames
var total_duration: float = 1.0
var durations: Array[float] = []
var cached_next: Texture2D

func _ready() -> void:
	sprite = get_parent() as AnimatedSprite2D
	effects = get_node("/root/VisualFX")
	blend_material = ShaderMaterial.new()
	blend_material.shader = BLEND_SHADER
	sprite.material = blend_material
	blend_material.set_shader_parameter("cloud_receiver", 1.0 if style == "foam" else 0.0)
	_update_visual()

func _process(delta: float) -> void:
	elapsed += delta
	_update_visual()

func _update_visual() -> void:
	var frames := sprite.sprite_frames
	var animation := sprite.animation
	if frames == null or not frames.has_animation(animation):
		return
	var count := frames.get_frame_count(animation)
	if count == 0:
		return
	if cached_frames != frames or cached_animation != animation:
		cached_frames = frames
		cached_animation = animation
		durations.clear()
		total_duration = 0.0
		for index in range(count):
			var length: float = frames.get_frame_duration(animation, index)
			durations.append(length)
			total_duration += length
	var current := clampi(sprite.frame, 0, count - 1)
	var backwards := sprite.get_playing_speed() < 0.0
	var next_index := current - 1 if backwards else current + 1
	if frames.get_animation_loop(animation):
		next_index = posmod(next_index, count)
	else:
		next_index = clampi(next_index, 0, count - 1)
	var next_texture: Texture2D = frames.get_frame_texture(animation, next_index)
	if cached_next != next_texture:
		cached_next = next_texture
		blend_material.set_shader_parameter("next_frame", next_texture)
	var mix_amount := 1.0 - sprite.frame_progress if backwards else sprite.frame_progress
	var current_texture: Texture2D = frames.get_frame_texture(animation, current)
	if not effects.enabled or not sprite.is_playing() or current_texture is AtlasTexture or next_texture is AtlasTexture:
		mix_amount = 0.0
	elif current_texture.get_size() != next_texture.get_size():
		mix_amount = 0.0
	blend_material.set_shader_parameter("frame_mix", mix_amount)
	var progress := durations[current] * sprite.frame_progress
	for index in range(current):
		progress += durations[index]
	progress /= maxf(total_duration, 0.001)
	var scale_amount := 1.0
	var opacity := 1.0
	var outer_fade := 0.0
	var shift := Vector2.ZERO
	if effects.enabled:
		if style == "foam":
			scale_amount = 1.0 + 0.018 * sin(elapsed * 3.2)
		elif style == "smoke":
			scale_amount = lerpf(0.98, 1.07, progress)
			opacity = 1.0 - smoothstep(0.18, 0.82, progress) * 0.90
			outer_fade = smoothstep(0.18, 0.75, progress) * 0.85
			shift.y = -4.0 * progress / maxf(absf(sprite.global_scale.y), 0.05)
		elif style == "explosion":
			scale_amount = lerpf(0.98, 1.04, progress)
			opacity = 1.0 - smoothstep(0.24, 0.90, progress) * 0.78
			outer_fade = smoothstep(0.18, 0.75, progress) * 0.85
	blend_material.set_shader_parameter("outer_fade", outer_fade)
	blend_material.set_shader_parameter("art_scale", scale_amount)
	blend_material.set_shader_parameter("art_shift", shift)
	blend_material.set_shader_parameter("art_opacity", opacity)
