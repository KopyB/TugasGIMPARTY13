extends Camera2D


# Called when the node enters the scene tree for the first time.
func _ready():
	cameraeffects.register_camera(self)
	cameraeffects.register_overlay($darken/jumpscare)
