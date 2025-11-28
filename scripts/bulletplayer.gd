extends Area2D

@export var speed = 1000

func _process(delta):
	var direction = Vector2.UP.rotated(rotation)
	position += direction * speed * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_body_entered(body) -> void: # cek bullet hit
	hit_something(body)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_bullet"):
		return # IGNORE SELF QUEUE.FREE WHILE MULTISHOT
	
	if area.has_method("take_damage"):
		area.take_damage(1)
		queue_free()
	
func hit_something(target):
	# Cek apakah target punya nyawa/bisa mati
	if target.has_method("take_damage"):
		target.take_damage(1)
		queue_free() # Hapus peluru
		
	elif target.name == "BorderLeft" or "BorderRight":
		queue_free()
	
	
	
