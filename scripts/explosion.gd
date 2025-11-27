extends AnimatedSprite2D

@onready var explosion: AnimatedSprite2D = $"."
@onready var boomsfx: AudioStreamPlayer2D = $boomsfx
var explosion_type = "normal"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if explosion_type == "bone":
		exploded_bone()
	else:
		exploded()

func exploded():
	cameraeffects.shake(8.0, 0.25)
	explosion.show()
	boomsfx.play()
	explosion.play("boom")
	await explosion.animation_finished
	explosion.hide()
	await boomsfx.finished
	queue_free()

func exploded_bone():
	cameraeffects.shake(8.0, 0.25)
	explosion.show()
	boomsfx.play()
	explosion.play("boombone")
	await explosion.animation_finished
	explosion.hide()
	await boomsfx.finished
	queue_free()
