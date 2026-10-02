extends ParallaxBackground

const PACING = preload("res://scripts/voyage_pacing.gd")
@export var scroll_speed := 150.0

const WATER_SHADER = preload("res://scripts/water_polish.gdshader")
const OCEAN_SHADER = preload("res://scripts/ocean_motion.gdshader")
var water_material: ShaderMaterial
var ocean_material: ShaderMaterial
var ocean_surface: ColorRect
var motion_time: float = 0.0
var ocean_scroll: float = 0.0
var smooth_active: bool = false

func _ready() -> void:
	# Update the water after camera effects, so both sample the same frame.
	process_priority = 100
	if get_parent().scene_file_path == "res://scenes/main.tscn":
		scroll_speed = PACING.current_speed(GameData.is_hard_mode)
	scroll_ignore_camera_zoom = false
	# The visible sprite owns its shader. The legacy shader remains on UI icons.
	$ParallaxLayer2.material = null
	water_material = ShaderMaterial.new()
	water_material.shader = WATER_SHADER
	$ParallaxLayer2/Sprite2D.material = water_material
	ocean_material = ShaderMaterial.new()
	ocean_material.shader = OCEAN_SHADER
	var source: Texture2D = $ParallaxLayer2/Sprite2D.sprite_frames.get_frame_texture(&"default", 0)
	ocean_material.set_shader_parameter("water_texture", source)
	ocean_material.set_shader_parameter("source_size", Vector2(source.get_size()))
	ocean_surface = ColorRect.new()
	ocean_surface.name = "ContinuousOcean"
	ocean_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ocean_surface.material = ocean_material
	add_child(ocean_surface)
	ocean_surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ocean_surface.resized.connect(_update_surface_size)
	_update_surface_size()
	VisualFX.settings_changed.connect(_apply_visual_settings)
	_apply_visual_settings()
	if not Transition.ocean_handoff.is_empty():
		restore_ocean_state(Transition.ocean_handoff)
		Transition.ocean_handoff.clear()
	_process(0.0)

func capture_ocean_state() -> Dictionary:
	return {"motion_time": motion_time, "ocean_scroll": ocean_scroll,
		"base_offset": scroll_base_offset, "frame": $ParallaxLayer2/Sprite2D.frame,
		"frame_progress": $ParallaxLayer2/Sprite2D.frame_progress}

func restore_ocean_state(state: Dictionary) -> void:
	motion_time = state.get("motion_time", 0.0)
	ocean_scroll = state.get("ocean_scroll", 0.0)
	scroll_base_offset = state.get("base_offset", Vector2.ZERO)
	$ParallaxLayer2/Sprite2D.set_frame_and_progress(state.get("frame", 0), state.get("frame_progress", 0.0))
	_process(0.0)

func _update_surface_size() -> void:
	ocean_material.set_shader_parameter("viewport_size", ocean_surface.size)

func _apply_visual_settings() -> void:
	water_material.set_shader_parameter("strength", 1.0 if VisualFX.enabled else 0.0)
	water_material.set_shader_parameter("brightness", VisualFX.water_brightness)
	water_material.set_shader_parameter("contrast_softening", VisualFX.water_contrast_softening)
	ocean_material.set_shader_parameter("brightness", VisualFX.water_brightness)
	ocean_material.set_shader_parameter("contrast_softening", VisualFX.water_contrast_softening)
	ocean_material.set_shader_parameter("wave_amplitude", VisualFX.water_wave_amplitude)
	ocean_material.set_shader_parameter("highlight_shimmer", VisualFX.water_highlight_shimmer)
	smooth_active = VisualFX.enabled and VisualFX.smooth_water
	ocean_surface.visible = smooth_active
	$ParallaxLayer2.visible = not smooth_active
	if smooth_active:
		$ParallaxLayer2/Sprite2D.pause()
	else:
		$ParallaxLayer2/Sprite2D.play()

func _process(delta: float) -> void:
	var storm := StormFX.intensity if VisualFX.enabled else 0.0
	ocean_material.set_shader_parameter("storm", storm)
	ocean_material.set_shader_parameter("storm_flash", StormFX.lightning if VisualFX.enabled else 0.0)
	$ParallaxLayer2.modulate = Color.WHITE.lerp(Color(0.65, 0.79, 0.87), storm * 0.45)
	scroll_base_offset.y += scroll_speed * delta
	# A script-driven clock pauses with the scene, unlike the built-in shader TIME.
	motion_time += delta
	ocean_scroll = fposmod(ocean_scroll + scroll_speed * delta, 1080.0)
	if smooth_active:
		var camera := get_viewport().get_camera_2d()
		if camera != null:
			camera.force_update_scroll()
		var screen_to_world := get_viewport().get_canvas_transform().affine_inverse()
		ocean_material.set_shader_parameter("world_x", screen_to_world.x)
		ocean_material.set_shader_parameter("world_y", screen_to_world.y)
		ocean_material.set_shader_parameter("world_origin", screen_to_world.origin)
		ocean_material.set_shader_parameter("motion_time", motion_time)
		ocean_material.set_shader_parameter("scroll_y", ocean_scroll)
