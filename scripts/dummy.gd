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
	if randf() <= 0.9: 
		var powerup = powerup_scene.instantiate()
		powerup.global_position = global_position
		
		# Random angka acak 0 sampai 5 
		var random_type = randi() % 6 
		powerup.current_type = random_type
		
		get_tree().current_scene.call_deferred("add_child", powerup)
