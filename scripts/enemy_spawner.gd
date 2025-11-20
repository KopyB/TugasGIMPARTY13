extends Marker2D

var enemy_scene = preload("res://scenes/dummy.tscn") 

func _ready():
	spawn_enemy()

func spawn_enemy():
	var new_enemy = enemy_scene.instantiate()
	
	new_enemy.position = Vector2.ZERO
	new_enemy.enemy_died.connect(_on_enemy_died)
	add_child(new_enemy)


func _on_enemy_died():
	print("Musuh mati. Respawn dalam 2 detik...")
	await get_tree().create_timer(2.0).timeout
	spawn_enemy()
