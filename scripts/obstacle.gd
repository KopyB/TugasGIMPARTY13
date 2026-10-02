extends Area2D

const PACING = preload("res://scripts/voyage_pacing.gd")

enum Type {BONES, SHIPWRECK}
var current_type = Type.BONES
var hp = 2
var speed = 185.0
var is_destroyed := false 

var enemy_scene = preload("res://scenes/dummy.tscn")
var explosion_scene = preload("res://scenes/explosion.tscn")
var floating_text_scene = preload("res://scenes/FloatingText.tscn")

var is_maze_obstacle = false 

func setup_obstacle(type):
	add_to_group("obstacles")
	current_type = type
	var shipwreck = $shipwreck
	var bone = $bone
	var variants = ["A", "B", "C"]
	var pick = variants.pick_random()
	
	if current_type == Type.BONES:
		shipwreck.hide()
		bone.show()
		bone.play("bone" + pick)
		hp = 3
		scale = Vector2(1.2, 1.2)

	elif current_type == Type.SHIPWRECK:
		shipwreck.show()
		bone.hide()
		shipwreck.play("ship" + pick)
		hp = 5
		scale = Vector2(1.0, 1.0)
	
func _process(delta):
	position.y += speed * delta
	if global_position.y > 1080.0:
		var arena = preload("res://scripts/arena_geometry.gd")
		if not arena.RECT.intersects(arena.visual_bounds(self)):
			queue_free()

func take_damage(amount):
	if is_destroyed:
		return
	hp -= amount
	if hp <= 0:
		get_tree().call_group("ui_manager", "increase_score", 1)
		var txt = floating_text_scene.instantiate()
		txt.global_position = global_position
		get_tree().current_scene.add_child(txt)
		txt.start_animation("+1 Object", Color(0.423, 0.541, 0.564, 1))
		explode()

func _on_body_entered(body):
	if body.has_method("take_damage_player"):
		body.take_damage_player()
		explode()

func explode():
	if is_destroyed:
		return
	is_destroyed = true
	$CollisionShape2D.set_deferred("disabled", true)
	var explosion = explosion_scene.instantiate()
	explosion.global_position = global_position
	
	if current_type == Type.BONES:
		explosion.is_bone = true
	else:
		explosion.is_bone = false
	
	get_tree().current_scene.call_deferred("add_child", explosion)
	queue_free()

func _ready() -> void:
	speed = PACING.current_speed(GameData.is_hard_mode)
	for sprite in [$bone, $shipwreck]:
		sprite.light_mask = 2
		VisualFX.register_weather_sprite(sprite)
		var rim: Sprite2D = VisualFX.add_silhouette(self, sprite)
		rim.set("width", 1.1)
		rim.z_index = 5
	VisualFX.settings_changed.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	if not VisualFX.enabled:
		return
	var collider := $CollisionShape2D as CollisionShape2D
	if collider.disabled or not collider.shape is RectangleShape2D:
		return
	var half: Vector2 = collider.shape.size * 0.5
	for x in [-1.0, 1.0]:
		for y in [-1.0, 1.0]:
			var corner := collider.position + half * Vector2(x, y)
			var points := PackedVector2Array([corner - Vector2(x * 14, 0), corner, corner - Vector2(0, y * 14)])
			draw_polyline(points, Color(0.1, 0.3, 0.36, 0.65), 4, true)
			draw_polyline(points, Color(0.88, 1, 0.95, 0.85), 1.5, true)
