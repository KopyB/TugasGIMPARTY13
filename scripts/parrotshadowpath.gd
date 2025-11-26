extends PathFollow2D

var speed = 0.05
var is_paralyzed = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not is_paralyzed:
		progress_ratio += speed * delta
	if progress_ratio >= 0.99:
		queue_free()
	elif not is_instance_valid($"../../PathFollow2D/Area2D"):
		queue_free()
