extends Node
## Broad analytic normal maps, aligned to each original texture's artwork.
## No brightness-to-height conversion and no changes to source PNGs.
const NORMAL_SHADER = preload("res://scripts/actor_normals.gdshader")
const FLAT_SHADER = preload("res://scripts/actor_feedback.gdshader")
var allowed := true
var sprite: Node2D
var feedback: ShaderMaterial

# Center, radius and surface kind in texture pixels. 1 hull, 2 cannon, 3 barrel.
const PROFILES := {
	"player boat.png": [Vector2(291, 444), Vector2(130, 253), 1],
	"player left boat.png": [Vector2(309, 450), Vector2(127, 242), 1],
	"player right boat.png": [Vector2(272, 444), Vector2(132, 242), 1],
	"player canon.png": [Vector2(292, 164), Vector2(70, 84), 2],
	"player left canon.png": [Vector2(270, 177), Vector2(67, 87), 2],
	"player right canon.png": [Vector2(311, 172), Vector2(67, 87), 2],
	"pirate gunboat base.png": [Vector2(120, 139), Vector2(53, 88), 1],
	"pirate gunboat canon.png": [Vector2(141, 240), Vector2(30, 56), 2],
	"Barrel.png": [Vector2(300, 282), Vector2(195, 214), 3],
}

func _ready() -> void:
	sprite = get_parent() as Node2D
	feedback = sprite.material as ShaderMaterial
	if sprite is AnimatedSprite2D:
		sprite.animation_changed.connect(refresh)
		sprite.frame_changed.connect(refresh)
	elif sprite is Sprite2D:
		sprite.texture_changed.connect(refresh)
	get_node("/root/VisualFX").settings_changed.connect(refresh)
	refresh()

func refresh() -> void:
	if not is_instance_valid(sprite) or feedback == null:
		return
	var texture: Texture2D
	if sprite is AnimatedSprite2D:
		texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	elif sprite is Sprite2D:
		texture = sprite.texture
	var effects = get_node("/root/VisualFX")
	var key := texture.resource_path.get_file() if texture != null else ""
	var active: bool = allowed and effects.enabled and effects.normal_maps_enabled and PROFILES.has(key)
	feedback.shader = NORMAL_SHADER if active else FLAT_SHADER
	if not active:
		return
	var profile: Array = PROFILES[key]
	feedback.set_shader_parameter("normal_center", profile[0] / texture.get_size())
	feedback.set_shader_parameter("normal_radius", profile[1] / texture.get_size())
	feedback.set_shader_parameter("normal_kind", profile[2])
	feedback.set_shader_parameter("normal_strength", effects.normal_map_strength)
