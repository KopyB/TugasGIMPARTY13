extends StaticBody2D

#Beri signal saat musuh mati (BOSS EXCLUSIVE)
signal enemy_died

# Atur HP musuh, bisa diubah di Inspector
@export var health: int = 67
var powerup_scene = preload("res://scenes/power_up.tscn")

# Fungsi ini bekerja saat bullet kena dummy
func take_damage(amount: int):
	health -= amount
	print("HIT!!")
	print("Dummy HP= ", health," /67") 

	if health <= 0:
		enemy_died.emit()
		spawn_powerup_chance()
		queue_free()
		print("Dummy died")

func spawn_powerup_chance():
	# LAMA: if randf() <= 0.3:
	
	# BARU (Gunakan ini sementara untuk test):
	if randf() <= 1.0: 
		print("Mencoba spawn powerup...") # Debug print
		var powerup = powerup_scene.instantiate()
		powerup.global_position = global_position
		
		# Kita gunakan 'get_tree().current_scene' agar lebih aman
		# daripada 'get_parent()', untuk memastikan bola masuk ke World utama
		get_tree().current_scene.call_deferred("add_child", powerup)
