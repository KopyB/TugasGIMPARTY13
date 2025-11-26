extends Marker2D

var enemy_scene = preload("res://scenes/dummy.tscn")
var obstacle_scene = preload("res://scenes/obstacle.tscn")
var parrot_scene = preload("res://scenes/parrot.tscn")
@onready var spawn_timer = $SpawnTimer

# --- SETTING DIFFICULTY (WAVE SYSTEM) ---
var time_elapsed = 0.0
var wave_duration = 60.0

# 1. Setting Kecepatan Spawn (Sumbu Y)
var spawn_time_slow = 6.5  # Paling santai (Lembah gelombang)
var peak_difficulty_start = 4.0     # Puncak Gelombang 1 (4 detik - Santai)
var peak_difficulty_final = 0.5     # Puncak Gelombang 10++ (0.5 detik - Cepat)
var current_peak = peak_difficulty_start # Variable dinamis yang akan berubah

var wave_counter = 0                # Menghitung sudah berapa kali "Jeda" terjadi
var target_waves_to_max = 12.0      # Butuh 8 jeda untuk sampai max difficulty

var is_spawning_paused = false

func _ready():
	var viewport_rect = get_viewport_rect().size
	randomize()
	
	# WAJIB: Daftar ke group agar bisa diperintah oleh MazeSpawner
	add_to_group("spawner_utama") 
	
	spawn_timer.start(spawn_time_slow)

func _process(delta):
	if not is_spawning_paused:
		time_elapsed += delta # biar ga lompat ke puncak

# --- FUNGSI KONTROL (Dipanggil oleh MazeSpawner) ---
func pause_spawning():
	print(">>> SYSTEM: Musuh Biasa PAUSED (Maze Mulai) <<<")
	is_spawning_paused = true # Set flag pause
	spawn_timer.stop()        # Matikan timer fisik
	
func resume_spawning():
	print(">>> SYSTEM: Musuh Biasa RESUMED (Maze Selesai) <<<")
	# FUNGSI INI DIPANGGIL SAAT MAZE SELESAI
	# Artinya kita masuk ke Wave berikutnya
	
	is_spawning_paused = false 
	
	# Tambah Counter Wave
	wave_counter += 1
	
	# Hitung Kesulitan Puncak yang Baru
	# Rumus: (Wave Sekarang / Target 10) -> Hasilnya 0.0 sampai 1.0
	var progress_ratio = float(wave_counter) / target_waves_to_max
	
	# Clamp agar tidak melebihi 1.0 (Supaya tidak makin cepat dari 0.5)
	progress_ratio = clamp(progress_ratio, 0.0, 1.0)
	
	# Update Current Peak menggunakan Lerp
	# Jika ratio 0 (Awal) -> 4.0 detik
	# Jika ratio 0.5 (Wave 5) -> Sekitar 2.25 detik
	# Jika ratio 1.0 (Wave 10) -> 0.5 detik
	current_peak = lerp(peak_difficulty_start, peak_difficulty_final, progress_ratio)
	
	print(">>> Wave ke-%d Dimulai! Peak Speed sekarang: %.2f detik <<<" % [wave_counter, current_peak])
	
	# Reset posisi gelombang ke awal (Lembah/Slow) agar player napas dulu
	time_elapsed = 0.0 
	spawn_timer.start(spawn_time_slow)

func _on_spawn_timer_timeout():
	if is_spawning_paused:
		return

	spawn_logic()
	
	# --- IMPLEMENTASI GELOMBANG SINUS ---
	var frequency = (2.0 * PI) / wave_duration
	
	# Phase shift -PI/2 agar mulai dari lembah
	var sine_value = sin((time_elapsed * frequency) - (PI / 2.0))
	
	var difficulty_factor = (sine_value + 1.0) / 2.0
	
	var new_wait_time = lerp(spawn_time_slow, current_peak, difficulty_factor)
	
	spawn_timer.start(new_wait_time)

func spawn_logic():
	var parrotcheck = get_tree().get_nodes_in_group("parrots").size()
	var viewport_rect = get_viewport_rect().size
	
	# Randomizer Tipe Musuh (Total 100%)
	var chance = randi() % 100
	print(chance)
	
	# --- SUSUNAN PROBABILITAS BARU (Total 100%) ---
	# TOTAL HARUS 100%. SELALU FOLLOW SUSUNAN LIKE BELOW -nigga
	# 1. PARROT (Sangat Jarang: 5%)
	if chance < 5 and parrotcheck == 0 and get_tree().get_nodes_in_group("enemies").size() >= 1: 
		spawn_parrot(viewport_rect)

	# 2. GUNBOAT (40%) -> Range 5 sampai 39
	elif chance < 40: 
		spawn_gunboat_group(viewport_rect)
		
	# 3. BOMBER (25%) -> Range 40 sampai 64
	elif chance < 65: 
		if randf() > 0.5:
			spawn_bomber(viewport_rect)
		else:
			spawn_rbomber(viewport_rect)

	# 4. SHARK (15%) -> Range 65 sampai 79
	elif chance < 80:
		spawn_shark(viewport_rect)
	
	# 5. SIREN (10%) -> Range 85 sampai 89
	elif chance < 90:
		if randf() > 0.5:
			spawn_siren(viewport_rect)
		else:
			spawn_rsiren(viewport_rect)

	# 6. OBSTACLE (Sisanya 10%) -> Range 90 sampai 99
	else: 
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
		var enemyshape = new_enemy.get_node("enemyship")
		
		# Atur formasi berjejer (jarak antar kapal random dari 60 sampai lebar viewport - ukuran sprite/2)
		var viewport_width = get_viewport().get_visible_rect().size.x - enemyshape.get_rect().size.x*0.06/2
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

# --- TIPE 3A: BOMBER DARI KIRI (DEFAULT) ---
func spawn_bomber(viewport_rect):
	# --- LBOMBER (Spawn Sendiri dari Kiri) ---
	var new_enemy = enemy_scene.instantiate()
	new_enemy.enemy_type = 1 # LBomber
		
	var spawn_x = -60 # Di luar layar kiri
	var spawn_y = randf_range(50, viewport_rect.y / 2) 
	
	new_enemy.global_position = Vector2(spawn_x, spawn_y)
	get_tree().current_scene.add_child(new_enemy)


# --- TIPE 3B: RBOMBER DARI KANAN (BARU) ---
func spawn_rbomber(viewport_rect):
	var new_enemy = enemy_scene.instantiate()
	new_enemy.enemy_type = 2 # RBOMBER (Sesuai Enum di dummy.gd)
	
	# Spawn di luar layar KANAN
	var spawn_x = viewport_rect.x + 60 
	# Y acak (setengah atas layar)
	var spawn_y = randf_range(50, viewport_rect.y / 2) 
	
	new_enemy.global_position = Vector2(spawn_x, spawn_y)
	get_tree().current_scene.add_child(new_enemy)
  
func spawn_parrot(viewport_rect):
	var new_enemy = parrot_scene.instantiate()
	new_enemy.get_child(0).get_child(0).enemy_type = 3
  
	var spawn_x = 0
	var spawn_y = 0
	
	new_enemy.global_position = Vector2(spawn_x, spawn_y)
	add_child(new_enemy)
	new_enemy.get_child(0).get_child(0).add_to_group("parrots")
	print("Parrots alive: ", get_tree().get_nodes_in_group("parrots").size())

func spawn_shark(viewport_rect):
	var new_enemy = enemy_scene.instantiate()
	new_enemy.enemy_type = 4 # Tipe 4 = TORPEDO SHARK (Sesuai Enum)
	
	# Spawn di sembarang tempat di atas layar atau samping
	var spawn_side = randi() % 3 # 0=Atas, 1=Kiri, 2=Kanan
	var spawn_pos = Vector2.ZERO
	
	if spawn_side == 0: # Atas
		spawn_pos.x = randf_range(50, viewport_rect.x - 50)
		spawn_pos.y = -50
	elif spawn_side == 1: # Kiri
		spawn_pos.x = -50
		spawn_pos.y = randf_range(50, viewport_rect.y / 4)
	else: # Kanan
		spawn_pos.x = viewport_rect.x + 50
		spawn_pos.y = randf_range(50, viewport_rect.y / 4)
		
	new_enemy.global_position = spawn_pos
	get_tree().current_scene.add_child(new_enemy)

func spawn_siren(viewport_rect):
	var new_enemy = enemy_scene.instantiate()
	new_enemy.enemy_type = 5 # 4 = SIREN

	var spawn_x = -60
	var spawn_y = randf_range(50, viewport_rect.y / 2)
	new_enemy.global_position = Vector2(spawn_x,spawn_y)
	get_tree().current_scene.add_child(new_enemy)

func spawn_rsiren(viewport_rect):
	var new_enemy = enemy_scene.instantiate()
	new_enemy.enemy_type = 6 # 5 = RSIREN

	var spawn_x = viewport_rect.x + 60
	var spawn_y = randf_range(50, viewport_rect.y / 2)
	new_enemy.global_position = Vector2(spawn_x,spawn_y)
	get_tree().current_scene.add_child(new_enemy)
