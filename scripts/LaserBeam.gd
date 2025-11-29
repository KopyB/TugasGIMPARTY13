extends Area2D
#the
var damage_per_tick = 30 
var tick_timer = 0.0

func _process(delta):
	tick_timer += delta
	if tick_timer >= 0.1:
		tick_timer = 0.0
		apply_damage()

func apply_damage():
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body.has_method("take_damage"):
			body.take_damage(damage_per_tick)
	
	var areas = get_overlapping_areas()
	for area in areas:
		if area.has_method("take_damage"):
			area.take_damage(damage_per_tick)
