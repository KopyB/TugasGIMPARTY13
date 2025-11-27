extends AnimatedSprite2D

func _ready():
	play("strike")
	await animation_finished
	queue_free()
