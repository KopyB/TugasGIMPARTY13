extends PathFollow2D 

@onready var speed = 250

func _process(delta): 
	progress += speed * delta
	v_offset += 80 * delta
