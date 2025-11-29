extends AnimatedSprite2D

func _ready():
	#global_position.y = -200.0
	$".".play("nothing")
	$cloud.show()
	$cloud.play("cloudstart")
	await $cloud.animation_finished
	$cloud.hide()
	#global_position.y = -69.0
	$".".show()
	$".".play("lightning")
	await $".".animation_finished
	$".".play("nothing")
	#global_position.y = -200.0
	$cloud.show()
	$cloud.play("cloudend")
	await $cloud.animation_finished
	queue_free()
