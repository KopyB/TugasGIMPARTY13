extends Area2D

@export var speed = 1000

func _process(delta):
	position.y -= speed * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_body_entered(body: Node2D) -> void: # cek bullet hit
	if body.has_method("take_damage"):
		body.take_damage(1)
	queue_free() # delete bullet if hit
