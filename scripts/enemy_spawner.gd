extends Marker2D

var enemy_scene = preload("res://scenes/dummy.tscn")
var obstacle_scene = preload("res://scenes/Obstacle.tscn")

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
	
	if chance <= 40: 
		# 40% Chance: Gunboat Group
		spawn_gunboat_group(viewport_rect)
		
	elif chance <= 70: 
		# 30% Chance: Bomber
		spawn_bomber(viewport_rect)
		
	else: 
		# 30% Chance: Obstacle Satuan (Batu/Kapal Jatuh)
		spawn_single_obstacle(viewport_rect)

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
	
	for i in range(group_count):
		var new_enemy = enemy_scene.instantiate()
		new_enemy.enemy_type = 0 # Gunboat
		var enemyshape = new_enemy.get_node("Sprite2D")
		
		# Atur formasi berjejer (jarak antar kapal random dari 60 sampai lebar viewport - ukuran sprite/2)
		var viewport_width = get_viewport().get_visible_rect().size.x - enemyshape.get_rect().size.x/2
		#aku ganti logika spacingnya biar g fix 60 -kaiser
		var min_spacing = 60 #minimal 60 kyk kode awal
		var max_spacing = viewport_width / float(group_count - 1) #ngitung spacing paling jauh berdasarkan lebar viewport sm jumlah kapal
		var extra_spacing = randi_range(0, max_spacing - min_spacing) #ngitung jarak tambahan
		var spacing = min_spacing + extra_spacing #rumus jarak antar kapal yg baru
		# Tentukan posisi tengah grup
		var half_width = ((group_count - 1) / 2.0) * spacing #aku tambah var ini biar milih titik tengah yang kanan kirinya keluar viewport -kaiser
		var center_x = randf_range(half_width, viewport_width - half_width) #rumus baru center -kaiser

		var offset_x = (i - (group_count - 1) / 2.0) * spacing
		
		new_enemy.global_position = Vector2(center_x + offset_x, -60)
		get_tree().current_scene.add_child(new_enemy)

# --- TIPE 3: BOMBER DARI SAMPING ---
func spawn_bomber(viewport_rect):
	if randi() % 2 == 0:
		# --- LBOMBER (Spawn Sendiri dari Kiri) ---
		var new_enemy = enemy_scene.instantiate()
		new_enemy.enemy_type = 1 # LBomber
		
		var spawn_x = -60
		var spawn_y = randf_range(50, viewport_rect.y / 2)
		
		new_enemy.global_position = Vector2(spawn_x, spawn_y)
		get_tree().current_scene.add_child(new_enemy)
	else:
		# --- RBOMBER (Spawn Sendiri dari Kanan) ---
		var new_enemy = enemy_scene.instantiate()
		new_enemy.enemy_type = 2 # RBomber
		
		var spawn_x = viewport_rect.x + 60
		var spawn_y = randf_range(50, viewport_rect.y / 2)
		
		new_enemy.global_position = Vector2(spawn_x, spawn_y)
		get_tree().current_scene.add_child(new_enemy)
