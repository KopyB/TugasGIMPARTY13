extends Marker2D

var enemy_scene = preload("res://scenes/dummy.tscn")
<<<<<<< Updated upstream
var obstacle_scene = preload("res://scenes/Obstacle.tscn")

=======
var parrot_scene = preload("res://scenes/Parrot.tscn")
>>>>>>> Stashed changes
@onready var spawn_timer = $SpawnTimer

# --- SETTING DIFFICULTY ---
var time_elapsed = 0.0
var initial_spawn_rate = 7.0 # Spawn awal tiap 7 detik
var min_spawn_rate = 0.5     # Paling ngebut tiap 0.8 detik
var difficulty_curve = 0.05  # Kecepatan kenaikan difficulty

# Flag manual untuk status pause (Pengganti is_stopped yang nge-bug)
var is_spawning_paused = false 

func _ready():
	randomize()
	
	# WAJIB: Daftar ke group agar bisa diperintah oleh MazeSpawner
	add_to_group("spawner_utama") 
	
	spawn_timer.start(initial_spawn_rate)

func _process(delta):
	time_elapsed += delta

# --- FUNGSI KONTROL (Dipanggil oleh MazeSpawner) ---
func pause_spawning():
	print(">>> SYSTEM: Musuh Biasa PAUSED (Maze Mulai) <<<")
	is_spawning_paused = true # Set flag pause
	spawn_timer.stop()        # Matikan timer fisik

func resume_spawning():
	print(">>> SYSTEM: Musuh Biasa RESUMED (Maze Selesai) <<<")
	is_spawning_paused = false # Lepas flag pause
	# Mulai lagi dengan delay 1 detik agar player tidak kaget
	spawn_timer.start(1.0)

func _on_spawn_timer_timeout():
	# Jika sedang dipause oleh Maze, jangan lanjut spawn.
	if is_spawning_paused:
		return

	spawn_logic()
	
	# --- DIFFICULTY CALCULATION ---
	# Rumus: Waktu Awal - (Waktu Main x Faktor Kesulitan)
	var new_wait_time = initial_spawn_rate - (time_elapsed * difficulty_curve)
	
	# Cap di min_spawn_rate
	if new_wait_time < min_spawn_rate:
		new_wait_time = min_spawn_rate
	
	spawn_timer.start(new_wait_time)

func spawn_logic():
	var viewport_rect = get_viewport_rect().size
	
	# Randomizer Tipe Musuh (Persentase)
	var chance = randi() % 100
	
<<<<<<< Updated upstream
	if chance <= 40: 
		# 40% Chance: Gunboat Group
		spawn_gunboat_group(viewport_rect)
=======
	
	if type_rng < 0: #chance gunboat lebih sering, jdi 70% - kaiser
		# --- GUNBOAT (Spawn Berkelompok 1-3) ---
		var group_count = randi_range(1, 3) # Random 1 sampai 3 kapal
>>>>>>> Stashed changes
		
	elif chance <= 70: 
		# 30% Chance: Bomber
		spawn_bomber(viewport_rect)
		
	else: 
		# 30% Chance: Obstacle Satuan (Batu/Kapal Jatuh)
		spawn_single_obstacle(viewport_rect)

<<<<<<< Updated upstream
# --- TIPE 1: OBSTACLE SATUAN ---
func spawn_single_obstacle(viewport_rect):
	var obs = obstacle_scene.instantiate()
	
	# Random Tipe (0 = Bones, 1 = Shipwreck)
	var type = randi() % 2
	obs.setup_obstacle(type) 
	
	# Posisi X acak, Y di atas layar
	var spawn_x = randf_range(60, viewport_rect.x - 60)
	obs.global_position = Vector2(spawn_x, -80)
	
	get_tree().current_scene.add_child(obs)

# --- TIPE 2: GUNBOAT BERKELOMPOK ---
func spawn_gunboat_group(viewport_rect):
	var group_count = randi_range(1, 3) # 1 sampai 3 kapal
	var center_x = randf_range(100, viewport_rect.x - 100)
	
	for i in range(group_count):
		var new_enemy = enemy_scene.instantiate()
		new_enemy.enemy_type = 0 # Gunboat
		
		# Hitung offset agar berjejer rapi
		var offset_x = (i - (group_count - 1) / 2.0) * 60
		
		new_enemy.global_position = Vector2(center_x + offset_x, -60)
		get_tree().current_scene.add_child(new_enemy)

# --- TIPE 3: BOMBER DARI SAMPING ---
func spawn_bomber(viewport_rect):
	var new_enemy = enemy_scene.instantiate()
	new_enemy.enemy_type = 1 # Bomber
	
	var spawn_x = -60 # Di kiri layar
	var spawn_y = randf_range(50, viewport_rect.y / 2) # Y acak (setengah atas layar)
	
	new_enemy.global_position = Vector2(spawn_x, spawn_y)
	get_tree().current_scene.add_child(new_enemy)
=======
			var offset_x = (i - (group_count - 1) / 2.0) * spacing
			
			new_enemy.global_position = Vector2(center_x + offset_x, -60)
			get_tree().current_scene.add_child(new_enemy)
			
		if randi() % 2 == 0:
			# --- BOMBER (Spawn Sendiri dari Kiri) ---
			var new_enemy = enemy_scene.instantiate()
			new_enemy.enemy_type = 1 # Bomber
			
			var spawn_x = -60
			var spawn_y = randf_range(50, viewport_rect.y / 2)
			
			new_enemy.global_position = Vector2(spawn_x, spawn_y)
			get_tree().current_scene.add_child(new_enemy)
		else:
			# --- BOMBER (Spawn Sendiri dari Kanan) ---
			var new_enemy = enemy_scene.instantiate()
			new_enemy.enemy_type = 2 # RBomber
			
			var spawn_x = viewport_rect.x + 60
			var spawn_y = randf_range(50, viewport_rect.y / 2)
			
			new_enemy.global_position = Vector2(spawn_x, spawn_y)
			get_tree().current_scene.add_child(new_enemy)
	else:
			# --- Parrot  (Spawn Sendiri dari atas) ---
			var new_enemy = parrot_scene.instantiate()
			
			var spawn_x = randf_range(20, viewport_rect.x / 2)
			var spawn_y = 0
			
			new_enemy.global_position = Vector2(spawn_x, spawn_y)
			get_tree().current_scene.add_child(new_enemy)
>>>>>>> Stashed changes
