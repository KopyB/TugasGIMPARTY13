extends Node
## Apply a common visual transform to separate sprite layers without moving physics.

const FEEDBACK_SHADER = preload("res://scripts/actor_feedback.gdshader")
var actor: Node2D
var effects
var sprites: Array[Node2D] = []
var elapsed: float = 0.0
var phase: float = 0.0
var was_active: bool = false

func _ready() -> void:
	actor = get_parent() as Node2D
	effects = get_node("/root/VisualFX")
	phase = fposmod(actor.position.x * 0.01 + actor.position.y * 0.013, TAU)
	for child in actor.get_children():
		if child is Node2D and child.material is ShaderMaterial:
			if effects.is_feedback_material(child.material):
				sprites.append(child)

func _process(delta: float) -> void:
	elapsed += delta
	var active: bool = effects.enabled and actor.is_visible_in_tree()
	active = active and actor.get("is_dead") != true and actor.get("is_game_over") != true
	active = active and actor.get("is_paralyzed") != true
	if not active:
		if was_active:
			for sprite in sprites:
				_write_transform(sprite.material as ShaderMaterial, Transform2D.IDENTITY)
		was_active = false
		return
	was_active = true
	var amount: float = effects.actor_motion_amount
	var bob := sin(elapsed * 1.65 + phase) * 1.6 * amount
	var roll := sin(elapsed * 1.1 + phase + 0.5) * 0.008 * amount
	for sprite in sprites:
		if not is_instance_valid(sprite):
			continue
		var extra := 0.0
		if sprite.name == &"stellarist":
			extra = sin(elapsed * 2.0 + phase + 0.7) * 0.55 * amount
		var motion := Transform2D(roll, Vector2(0.0, bob + extra))
		# Conjugation keeps mirrored/rotated hulls, cannons and portraits together.
		var local_motion := sprite.transform.affine_inverse() * motion * sprite.transform
		_write_transform(sprite.material as ShaderMaterial, local_motion)

func _write_transform(material: ShaderMaterial, transform: Transform2D) -> void:
	material.set_shader_parameter("motion_x", transform.x)
	material.set_shader_parameter("motion_y", transform.y)
	material.set_shader_parameter("motion_origin", transform.origin)
