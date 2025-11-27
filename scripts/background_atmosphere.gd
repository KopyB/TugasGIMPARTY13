extends ParallaxBackground
@export var scroll_speed := 150.0

func _ready() -> void:
	$ParallaxLayer2/Sprite2D.play()
func _process(delta):
	scroll_base_offset.y += scroll_speed * delta
