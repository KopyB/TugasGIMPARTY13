extends CharacterBody2D

var target_position : Vector2
const SPEED = 500.0
var rotation_speed = 2
var rotation_direction = 0

var bullet_scene = preload("res://scenes/bulletplayer.tscn")

func _ready():
	target_position = global_position # Store initial position as center
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		move_and_slide()
	else:
		var direction_to_center = (target_position - global_position).normalized()
		if global_position.distance_to(target_position) > 0.05: # Check if not at center
			velocity.x = lerp(velocity.x, direction_to_center.x * 300, delta * 0.9) #slowly make itsw way to the centerr
			rotation = lerp(rotation, direction_to_center.x * 2.5, delta * 0.2) #slowly adjust its rotation
			move_and_slide()
		else: #sudah di center
			global_position = target_position
			velocity = Vector2.ZERO
			rotation = lerp(rotation, 0.0, delta * 1.0)
	
	# rotasi kapal
	rotation_direction = Input.get_axis("ui_left", "ui_right")
	var rot = rotation
	if velocity.x != 0:
		rot += rotation_direction * rotation_speed * delta
		var rotation_minmax = clamp(rot, -PI/8, PI/8) #max dan min rotasi
		rotation = rotation_minmax

	#move_and_slide()


func _on_timer_timeout() -> void: # BURST MODE
	var bullet = bullet_scene.instantiate()
	bullet.global_position = $FiringPosition.global_position #adjust starting firing position
	
	get_parent().add_child(bullet)
