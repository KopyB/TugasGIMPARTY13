extends PathFollow2D

var speed = 0.05
@onready var anim = $Area2D/ParrotAnim

func _ready():
	anim.play("parrot")           # play animation
	
func _process(delta):
	progress_ratio += speed * delta
	if progress_ratio >= 0.99:
		queue_free()
