extends Marker2D

var enemy_scene = preload("res://scenes/dummy.tscn")
@onready var spawn_timer = $SpawnTimer

# --- SETTING DIFFICULTY ---
var time_elapsed = 0.0
var initial_spawn_rate = 10.0 # REQUEST: Awal game 10 detik
var min_spawn_rate = 0.5      # Paling cepat 0.5 detik
var difficulty_curve = 0.05   # Seberapa cepat jadi susah

func _ready():
	randomize()
	spawn_timer.start(initial_spawn_rate)

func _process(delta):
	time_elapsed += delta

func _on_spawn_timer_timeout():
	spawn_logic()
	
	# Hitung waktu spawn berikutnya (Linear Difficulty)
	var new_wait_time = initial_spawn_rate - (time_elapsed * difficulty_curve)
	if new_wait_time < min_spawn_rate:
		new_wait_time = min_spawn_rate
	
	spawn_timer.start(new_wait_time)

func spawn_logic():
	var viewport_rect = get_viewport_rect().size
	var type_rng = randi() % 2 # 0 = Gunboat, 1 = Bomber
	
	if type_rng == 0: 
		# --- GUNBOAT (Spawn Berkelompok 1-3) ---
		var group_count = randi_range(1, 3) # Random 1 sampai 3 kapal
		
		# Tentukan posisi tengah grup
		var center_x = randf_range(100, viewport_rect.x - 100)
		
		for i in range(group_count):
			var new_enemy = enemy_scene.instantiate()
			new_enemy.enemy_type = 0 # Gunboat
			
			# Atur formasi berjejer (jarak antar kapal 60 pixel)
			# Logic: Jika 3 kapal, offsetnya: -60, 0, +60
			var offset_x = (i - (group_count - 1) / 2.0) * 60
			
			new_enemy.global_position = Vector2(center_x + offset_x, -60)
			get_tree().current_scene.add_child(new_enemy)
			
	else: 
		# --- BOMBER (Spawn Sendiri dari Kiri) ---
		var new_enemy = enemy_scene.instantiate()
		new_enemy.enemy_type = 1 # Bomber
		
		var spawn_x = -60
		var spawn_y = randf_range(50, viewport_rect.y / 2)
		
		new_enemy.global_position = Vector2(spawn_x, spawn_y)
		get_tree().current_scene.add_child(new_enemy)
