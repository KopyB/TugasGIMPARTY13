extends Node
## Visual-only controls. Edit this singleton's scene to tune the pass.

signal settings_changed

const PULSE_SCRIPT = preload("res://scripts/visual_pulse.gd")
const WAKE_SCRIPT = preload("res://scripts/wake_puff.gd")
const EMITTER_SCRIPT = preload("res://scripts/wake_emitter.gd")
const FEEDBACK_SHADER = preload("res://scripts/actor_feedback.gdshader")
const NORMAL_SHADER = preload("res://scripts/actor_normals.gdshader")
const NORMAL_SURFACE = preload("res://scripts/normal_trial_surface.gd")
const MOTION_SCRIPT = preload("res://scripts/actor_motion.gd")
const BLEND_SCRIPT = preload("res://scripts/effect_blend.gd")

@export var enabled: bool = true
@export var smooth_water: bool = true
@export var normal_maps_enabled := true
@export_range(0.0, 1.0) var normal_map_strength := 0.65
@export_range(0.0, 24.0) var water_wave_amplitude: float = 10.0
@export_range(0.0, 1.0) var water_highlight_shimmer: float = 0.40
@export_range(0.0, 2.0) var actor_motion_amount: float = 1.0
@export_range(0.5, 1.2) var water_brightness: float = 1.0
@export_range(0.0, 0.8) var water_contrast_softening: float = 0.55
@export_range(0.0, 3.0) var event_light_energy: float = 1.45
@export_range(0, 12) var max_event_lights: int = 6
@export_range(0, 96) var max_wake_puffs: int = 48

var glow_texture: GradientTexture2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.28, 0.62, 1.0])
	gradient.colors = PackedColorArray([
		Color(1, 1, 1, 1), Color(1, 1, 1, 0.55),
		Color(1, 1, 1, 0.12), Color(1, 1, 1, 0)
	])
	glow_texture = GradientTexture2D.new()
	glow_texture.width = 128
	glow_texture.height = 128
	glow_texture.gradient = gradient
	glow_texture.fill = GradientTexture2D.FILL_RADIAL
	glow_texture.fill_from = Vector2(0.5, 0.5)
	glow_texture.fill_to = Vector2(0.5, 0.0)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.physical_keycode == KEY_F6:
		enabled = not enabled
		if not enabled:
			get_tree().call_group("rw_transient_fx", "queue_free")
		settings_changed.emit()
		get_viewport().set_input_as_handled()
	elif key.physical_keycode == KEY_F7:
		normal_maps_enabled = not normal_maps_enabled
		settings_changed.emit()
		get_node("/root/BuildInfo").show_normal_status(normal_maps_enabled and enabled)
		get_viewport().set_input_as_handled()
	elif key.physical_keycode == KEY_F10:
		var scene := get_tree().current_scene
		if scene != null and scene.scene_file_path == "res://scenes/main_menu.tscn" and not Transition.busy:
			Transition.load_scene("res://scenes/normal_comparison.tscn")
			get_viewport().set_input_as_handled()
	elif key.physical_keycode == KEY_F8:
		smooth_water = not smooth_water
		settings_changed.emit()
		get_viewport().set_input_as_handled()

func register_actor(actor: Node2D, add_wake: bool = false) -> void:
	var names := ["shipbase", "cannon", "stellarist", "burst_turret",
		"multiturret", "multiburst", "KSturret", "enemyship",
		"torpedoshark", "siren", "ParrotAnim"]
	for child_name in names:
		var sprite := actor.get_node_or_null(NodePath(child_name)) as CanvasItem
		if sprite == null:
			continue
		# Only these actor visuals receive event lights. Bullets and UI keep mask 1.
		sprite.light_mask = 2
		register_weather_sprite(sprite)
		if actor.has_node("shipbase") and child_name in ["shipbase", "cannon"]:
			register_normal_trial(sprite)
		elif actor.get("enemy_type") == 0 and child_name in ["enemyship", "cannon"]:
			register_normal_trial(sprite)
	if not actor.has_node("VisualMotion"):
		var motion := MOTION_SCRIPT.new()
		motion.name = "VisualMotion"
		actor.add_child(motion)
	if actor.has_node("shipbase") and not actor.has_meta("rw_outline"):
		actor.set_meta("rw_outline", true)
		add_silhouette(actor, actor.get_node("shipbase"), true)
	var trail := actor.get_node_or_null("trails") as AnimatedSprite2D
	if trail != null:
		register_animation(trail, "foam")
	if add_wake and not actor.has_node("WakeEmitter"):
		var emitter := EMITTER_SCRIPT.new()
		emitter.name = "WakeEmitter"
		actor.add_child(emitter)

func is_feedback_material(material: Material) -> bool:
	return material is ShaderMaterial and material.shader in [FEEDBACK_SHADER, NORMAL_SHADER]

func register_normal_trial(sprite: Node2D, allowed: bool = true) -> void:
	register_weather_sprite(sprite)
	var surface := sprite.get_node_or_null("NormalTrial")
	if surface == null:
		surface = NORMAL_SURFACE.new()
		surface.name = "NormalTrial"
		surface.allowed = allowed
		sprite.add_child(surface)
	else:
		surface.allowed = allowed
		surface.refresh()

func register_weather_sprite(sprite: CanvasItem) -> void:
	# Share cloud shading without adding motion to static props or the menu hull.
	if sprite.material == null:
		var feedback := ShaderMaterial.new()
		feedback.shader = FEEDBACK_SHADER
		sprite.material = feedback

func add_silhouette(actor: Node2D, source: Node2D, near_blasts: bool = false) -> Sprite2D:
	var rim := preload("res://scripts/silhouette.gd").new()
	rim.source = source
	rim.only_near_blasts = near_blasts
	actor.add_child(rim)
	return rim

func register_animation(sprite: AnimatedSprite2D, style: String) -> void:
	if sprite == null or sprite.material != null or sprite.has_node("VisualBlend"):
		return
	var blend := BLEND_SCRIPT.new()
	blend.name = "VisualBlend"
	blend.style = style
	sprite.add_child(blend)

func hit(actor: Node2D) -> void:
	if not enabled or not is_instance_valid(actor):
		return
	var old_tween = actor.get_meta("rw_hit_tween") if actor.has_meta("rw_hit_tween") else null
	if old_tween is Tween and old_tween.is_valid():
		old_tween.kill()
	var tween := actor.create_tween().set_parallel(true)
	actor.set_meta("rw_hit_tween", tween)
	for child in actor.get_children():
		if child is CanvasItem and child.material is ShaderMaterial:
			var feedback := child.material as ShaderMaterial
			if is_feedback_material(feedback):
				feedback.set_shader_parameter("flash_amount", 0.8)
				tween.tween_property(feedback, "shader_parameter/flash_amount", 0.0, 0.12)

func recoil(sprite: Node2D) -> void:
	if not enabled or not is_instance_valid(sprite):
		return
	var feedback := sprite.material as ShaderMaterial
	if not is_feedback_material(feedback):
		return
	var old_tween = sprite.get_meta("rw_recoil_tween") if sprite.has_meta("rw_recoil_tween") else null
	if old_tween is Tween and old_tween.is_valid():
		old_tween.kill()
	var tween := sprite.create_tween()
	sprite.set_meta("rw_recoil_tween", tween)
	feedback.set_shader_parameter("recoil_amount", 3.0 / maxf(absf(sprite.scale.y), 0.05))
	tween.tween_property(feedback, "shader_parameter/recoil_amount", 0.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func muzzle(world_position: Vector2) -> void:
	_pulse.call_deferred(world_position, Color(1.0, 0.76, 0.34), 58.0, 0.12, false, false, 0.20)

func impact(world_position: Vector2) -> void:
	_pulse.call_deferred(world_position, Color(1.0, 0.9, 0.64), 38.0, 0.18, false, true, 0.22)

func blast(world_position: Vector2, bone: bool = false) -> void:
	var tint := Color(1.0, 0.62, 0.22)
	if bone:
		tint = Color(0.68, 0.87, 1.0)
	_pulse.call_deferred(world_position, tint, 360.0, 0.24, true, false, 0.56)
	_pulse.call_deferred(world_position, tint, 240.0, 0.24, false, true, 0.08)

func lightning(world_position: Vector2) -> void:
	_pulse.call_deferred(world_position, Color(0.48, 0.82, 1.0), 235.0, 0.24, true, true, 0.30)

func _pulse(world_position: Vector2, tint: Color, radius: float, duration: float,
		use_light: bool, ring: bool, opacity: float) -> void:
	if not enabled or not is_instance_valid(get_tree().current_scene):
		return
	if get_tree().get_nodes_in_group("rw_light_pulse").size() >= 24:
		return
	var pulse := PULSE_SCRIPT.new()
	pulse.top_level = true
	pulse.position = world_position
	pulse.tint = tint
	pulse.radius = radius
	pulse.duration = duration
	pulse.show_ring = ring
	pulse.opacity = opacity
	pulse.glow_texture = glow_texture
	if use_light and get_tree().get_nodes_in_group("rw_event_light").size() < max_event_lights:
		pulse.light_energy = event_light_energy
		pulse.add_to_group("rw_event_light")
	pulse.add_to_group("rw_light_pulse")
	pulse.add_to_group("rw_transient_fx")
	get_tree().current_scene.add_child(pulse)

func wake(world_position: Vector2, heading: float, strength: float, drift_speed: float = -1.0) -> void:
	if not enabled or not is_instance_valid(get_tree().current_scene):
		return
	if get_tree().get_nodes_in_group("rw_wake_puff").size() >= max_wake_puffs:
		return
	var puff := WAKE_SCRIPT.new()
	puff.top_level = true
	puff.drift_speed = drift_speed
	puff.position = world_position
	puff.rotation = heading
	puff.strength = strength
	puff.add_to_group("rw_wake_puff")
	puff.add_to_group("rw_transient_fx")
	get_tree().current_scene.add_child(puff)

func parrot_blocked(actor: Node2D) -> void:
	if not is_instance_valid(actor):
		return
	var parrots := get_tree().get_nodes_in_group("parrots")
	if parrots.is_empty():
		return
	var protector := parrots[0] as Node2D
	var sprite := protector.get_node_or_null("ParrotAnim") as AnimatedSprite2D
	var icon: Texture2D
	if sprite != null:
		icon = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	var cue = actor.get_node_or_null("ParrotGuardFeedback")
	if cue == null:
		cue = preload("res://scripts/parrot_guard_feedback.gd").new()
		cue.name = "ParrotGuardFeedback"
		actor.add_child(cue)
	cue.trigger(icon)
	var pulse = protector.get_node_or_null("ParrotGuardPulse")
	if pulse == null:
		pulse = preload("res://scripts/parrot_guard_feedback.gd").new()
		pulse.name = "ParrotGuardPulse"
		pulse.source_pulse = true
		protector.add_child(pulse)
	pulse.trigger()
