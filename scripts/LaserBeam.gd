extends Area2D

# Logika DPS:
# Misal Artillery DPS = 30. Maka Kraken = 20.
# Kita akan beri damage setiap 0.1 detik.
# Berarti damage per tick = 2. (2 damage * 10 tick/detik = 20 DPS)

var damage_per_tick = 30 
var tick_timer = 0.0

func _process(delta):
	# Timer manual untuk memberi damage per 0.1 detik
	tick_timer += delta
	if tick_timer >= 0.1:
		tick_timer = 0.0
		apply_damage()

func apply_damage():
	# Ambil semua body yang sedang menyentuh area laser ini
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body.has_method("take_damage"):
			body.take_damage(damage_per_tick)
