extends Area2D

const PACING = preload("res://scripts/voyage_pacing.gd")

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var barrel: Sprite2D = $barrel

var explosion_scene = preload("res://scenes/explosion.tscn")
var is_already_exploded = false
var fall_speed = randi_range(160,200)
var damage = 1
var is_fast_mode = false
var oil_warning
var float_clock := 0.0
var visual_rest_position := Vector2.ZERO
var visual_rest_rotation := 0.0

func _ready():
	add_to_group("enemy_projectiles")
	fall_speed = PACING.current_speed(GameData.is_hard_mode)
	barrel.light_mask = 2
	VisualFX.register_normal_trial(barrel)
	visual_rest_position = barrel.position
	visual_rest_rotation = barrel.rotation
	var blast = explosion_scene.instantiate()
	var blast_shape := blast.get_node("CollisionShape2D") as CollisionShape2D
	oil_warning = preload("res://scripts/bomb_warning.gd").new()
	oil_warning.name = "OilWarning"
	oil_warning.position = blast_shape.position
	oil_warning.radius = (blast_shape.shape as CircleShape2D).radius
	var fuse := randf_range(1.0, 1.5) if is_fast_mode else 0.0
	oil_warning.fuse_duration = fuse
	blast.free()
	add_child(oil_warning)
	if is_fast_mode:
		# Hard mode keeps its timed fuse, but it no longer propels the barrel.
		get_tree().create_timer(fuse, false).timeout.connect(_on_auto_explode)

func _process(delta):
	position.y += fall_speed * delta
	float_clock += delta
	barrel.position = visual_rest_position + Vector2(0, sin(float_clock * 2.7) * 1.8)
	barrel.rotation = visual_rest_rotation + sin(float_clock * 1.8) * 0.045
	_cleanup_if_offscreen()
	
func enable_fast_mode():
	is_fast_mode = true

func _on_auto_explode():
	if is_instance_valid(self) and not is_already_exploded:
		meledak()

func _on_body_entered(body):
	if body.has_method("take_damage_player"):
		body.take_damage_player()
		meledak()

# Logika Kena Tembak 
func take_damage(amount):
	meledak()

func meledak():
	if is_already_exploded:
		return
	is_already_exploded = true
	barrel.hide()
	oil_warning.hide()
	collision_shape_2d.set_deferred("disabled", true)
	exploded()
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	_cleanup_if_offscreen()

func _cleanup_if_offscreen() -> void:
	# Keep the warning until its whole area has drifted out, not just the barrel.
	if oil_warning != null and global_position.y - oil_warning.radius > 1112.0:
		queue_free()

func exploded():
	var explosion = explosion_scene.instantiate()
	explosion.global_position = global_position
	explosion.is_barrel_explosion = true
	get_tree().current_scene.call_deferred("add_child", explosion)
	queue_free()
