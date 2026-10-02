extends Node2D
## A short additive glow below actors, plus optional masked light on their art.

var tint: Color = Color.WHITE
var radius: float = 100.0
var duration: float = 0.3
var opacity: float = 0.25
var light_energy: float = 0.0
var show_ring: bool = false
var glow_texture: Texture2D
var light_mask_bits := 2
var elapsed: float = 0.0
var glow: Sprite2D
var event_light: PointLight2D

func _ready() -> void:
	z_index = 3
	glow = Sprite2D.new()
	glow.texture = glow_texture
	glow.scale = Vector2.ONE * radius * 2.0 / 128.0
	glow.modulate = Color(tint, opacity)
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	additive.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	glow.material = additive
	add_child(glow)
	if light_energy > 0.0:
		event_light = PointLight2D.new()
		event_light.texture = glow_texture
		event_light.texture_scale = radius * 2.0 / 128.0
		event_light.color = tint
		event_light.energy = light_energy
		event_light.range_item_cull_mask = light_mask_bits
		event_light.height = 160.0
		event_light.shadow_enabled = false
		add_child(event_light)

func _process(delta: float) -> void:
	elapsed += delta
	var progress := clampf(elapsed / duration, 0.0, 1.0)
	var fade := pow(1.0 - clampf((progress - 0.16) / 0.84, 0.0, 1.0), 1.5)
	glow.modulate.a = opacity * fade
	glow.scale = Vector2.ONE * radius * 2.0 / 128.0 * lerpf(0.8, 1.08, progress)
	if is_instance_valid(event_light):
		event_light.energy = light_energy * fade
	queue_redraw()
	if progress >= 1.0:
		queue_free()

func _draw() -> void:
	if not show_ring:
		return
	var progress := clampf(elapsed / duration, 0.0, 1.0)
	var ring_radius := lerpf(radius * 0.08, radius * 0.38, progress)
	var color := Color(0.82, 0.98, 1.0, 0.36 * (1.0 - progress))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.65))
	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 32, color, 2.0, true)
