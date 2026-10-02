extends Area2D

@onready var explosion: AnimatedSprite2D = $AnimatedSprite2D 
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var boomsfx: AudioStreamPlayer2D = $boomsfx
@onready var bonesfx: AudioStreamPlayer2D = $bone_boom
var is_bone = false

var explosion_type = "normal" 
var damaged_targets: Dictionary = {}
var damage_active := true
var is_barrel_explosion = false         

func _ready() -> void:
	add_to_group("rw_visible_blasts")
	VisualFX.register_animation(explosion, "smoke" if is_bone else "explosion")
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	
	if is_bone:
		exploded_bone()
	else:
		exploded()
		
func _physics_process(_delta: float) -> void:
	if not is_barrel_explosion or not damage_active:
		return
	# Poll too, so targets already inside at creation are included, and a shark
	# that stops charging inside a still-live blast becomes vulnerable again.
	for body in get_overlapping_bodies():
		_on_body_entered(body)
	for area in get_overlapping_areas():
		_on_area_entered(area)

func _on_body_entered(body: Node2D) -> void:
	if not is_barrel_explosion or not damage_active or not is_instance_valid(body):
		return
	var id := body.get_instance_id()
	if damaged_targets.has(id):
		return
	if body.is_in_group("player") and body.has_method("take_damage_player"):
		damaged_targets[id] = true
		body.take_damage_player()
		# Keep the blast active for other targets after the player is hit.

func _on_area_entered(area: Area2D) -> void:
	if not is_barrel_explosion or not damage_active or not is_instance_valid(area):
		return
	if area.is_queued_for_deletion():
		return
	var id := area.get_instance_id()
	if damaged_targets.has(id):
		return
	if area.is_in_group("enemies") and area.has_method("take_barrel_blast"):
		if area.take_barrel_blast():
			damaged_targets[id] = true
	elif area.is_in_group("enemy_projectiles") and area.has_method("meledak"):
		damaged_targets[id] = true
		area.call_deferred("meledak")

func exploded():
	VisualFX.blast(global_position)
	cameraeffects.shake(12.0, 0.25)
	explosion.show()
	boomsfx.play()
	explosion.play("boom")
	await explosion.animation_finished
	damage_active = false
	collision_shape.set_deferred("disabled", true)
	explosion.hide()
	remove_from_group("rw_visible_blasts")
	if boomsfx.playing:
		await boomsfx.finished
	queue_free()

func exploded_bone():
	VisualFX.blast(global_position, true)
	cameraeffects.shake(12.0, 0.25)
	explosion.show()
	bonesfx.play()
	explosion.play("boombone")
	await explosion.animation_finished
	damage_active = false
	collision_shape.set_deferred("disabled", true)
	explosion.hide()
	remove_from_group("rw_visible_blasts")
	if bonesfx.playing:
		await bonesfx.finished
	queue_free()

