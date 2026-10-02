extends Area2D

var speed = 800 # 800
var direction = Vector2.ZERO 
var explosion_scene = preload("res://scenes/explosion.tscn")

var source_actor_id := 0
var spent := false

func _ready():
	add_to_group("enemy_projectiles")
	set_collision_mask_value(1, true)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	_setup_visuals()

func _physics_process(delta: float) -> void:
	if spent:
		return
	position += direction * speed * delta
	if direction != drawn_direction:
		drawn_direction = direction
		queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if spent or not is_instance_valid(body):
		return
	if body.has_method("take_damage_player"):
		_consume(false)
		body.take_damage_player()

func _on_area_entered(area: Area2D) -> void:
	if spent or not is_instance_valid(area) or area.is_queued_for_deletion():
		return
	if area.get_instance_id() == source_actor_id:
		return
	if area.is_in_group("enemies"):
		if not area.has_method("takes_ground_hits") or not area.takes_ground_hits():
			return
		_consume(true)
		area.take_damage(1)
	elif area.is_in_group("obstacles"):
		_consume(true)
		area.take_damage(1)
	elif area.has_method("meledak"):
		# Barrels share enemy_projectiles with cannonballs, so test them first.
		if area.get("is_already_exploded") != null:
			_consume(true)
			area.meledak()

func _consume(with_impact: bool) -> void:
	if spent:
		return
	spent = true
	hide()
	$CollisionShape2D.set_deferred("disabled", true)
	if with_impact:
		exploded()
	queue_free()

func meledak() -> void:
	_consume(true)

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
	
func exploded():
	var explosion = explosion_scene.instantiate()
	explosion.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", explosion)

# The bright rim fits in the existing PNG's transparent padding.
# Sprite size, collision radius, projectile speed and damage stay unchanged.
var readability_material: ShaderMaterial
var drawn_direction := Vector2.ZERO

func _setup_visuals() -> void:
	readability_material = ShaderMaterial.new()
	readability_material.shader = preload("res://scripts/hostile_projectile.gdshader")
	$Sprite2D.material = readability_material
	VisualFX.settings_changed.connect(_apply_visual_settings)
	_apply_visual_settings()

func _apply_visual_settings() -> void:
	readability_material.set_shader_parameter("strength", 1.0 if VisualFX.enabled else 0.0)
	queue_redraw()

func _draw() -> void:
	if not VisualFX.enabled or direction.is_zero_approx():
		return
	var heading := direction.normalized()
	draw_line(-heading * 12.0, -heading * 25.0, Color(1.0, 0.64, 0.76, 0.24), 3.0, true)
