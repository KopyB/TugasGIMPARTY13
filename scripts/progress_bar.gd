extends ProgressBar



func start_countdown(duration: float):
	max_value = duration
	value = duration
	$Timer.set_wait_time(duration)
	$Timer.start()
	
func _process(delta: float) -> void:
	if not $Timer.is_stopped():
		value = $Timer.get_time_left()
