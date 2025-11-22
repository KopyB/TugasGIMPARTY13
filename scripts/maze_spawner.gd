extends Node2D

var obstacle_scene = preload("res://scenes/Obstacle.tscn")
var columns = 8          
var block_size = 60      
var spawn_y = -100       
var rows_to_spawn = 8      
var rows_spawned_count = 0
var is_spawning = false    

var maze_row_interval = 2.0
var maze_timer = 0.0

var cooldown_timer = 0.0
var next_event_time = 45.0 

var current_gap_index = 4  

func _ready():
	var screen_width = get_viewport_rect().size.x
	block_size = screen_width / columns
	randomize()
	next_event_time = randf_range(45.0, 60.0)

func _process(delta):
	# LOGIKA STATE MACHINE DIPERBAIKI
	if not is_spawning:
		# --- FASE 1: MENUNGGU (COOLDOWN) ---
		cooldown_timer += delta
		if cooldown_timer >= next_event_time:
			start_maze_event()
	else:
		# --- FASE 2: GENERATE MAZE ---
		maze_timer += delta
		if maze_timer >= maze_row_interval:
			maze_timer = 0
			spawn_maze_row()

func start_maze_event():
	print("!!! EVENT MAZE DIMULAI - STOP MUSUH BIASA !!!")
	is_spawning = true
	rows_spawned_count = 0
	cooldown_timer = 0 # Reset cooldown timer

	# Tentukan posisi celah awal
	current_gap_index = randi() % (columns - 2) + 1

	# STOP MUSUH BIASA: Panggil fungsi pause di EnemySpawner
	get_tree().call_group("spawner_utama", "pause_spawning")

func end_maze_event():
	print("!!! EVENT MAZE SELESAI - START MUSUH BIASA !!!")
	is_spawning = false
	
	# Reset waktu event berikutnya
	next_event_time = randf_range(45.0, 70.0) 

	# START MUSUH BIASA: Resume spawning
	get_tree().call_group("spawner_utama", "resume_spawning")

func spawn_maze_row():
	# Cek apakah sudah selesai spawn semua baris
	if rows_spawned_count >= rows_to_spawn:
		end_maze_event()
		return # Return HANYA jika event selesai

	# --- PERBAIKAN UTAMA DI SINI ---
	# Sebelumnya ada 'return' di sini yang membuat kode di bawah mati.
	# Sekarang kode akan lanjut jalan ke bawah.
	
	rows_spawned_count += 1

	# --- ALGORITMA WINDING PATH ---
	var move = randi() % 3 - 1 
	if randf() < 0.2:
		move = move * 2
	
	current_gap_index += move
	current_gap_index = clamp(current_gap_index, 1, columns - 2)

	# Spawn Obstacle
	for i in range(columns):
		# Kosongkan celah dan tetangganya
		if i == current_gap_index or i == current_gap_index + 1:
			continue 
	
		# Chance spawn obstacle 70%
		if randf() > 0.3:
			spawn_obstacle_at_column(i)

func spawn_obstacle_at_column(col_index):
	var obs = obstacle_scene.instantiate()

	# Hitung posisi X tengah kolom
	var pos_x = (col_index * block_size) + (block_size / 2)
	obs.position = Vector2(pos_x, spawn_y)

	# --- FIX: Set flag ini menjadi TRUE agar obstacle tidak membawa musuh ---
	obs.is_maze_obstacle = true 

	# Random Tipe (70% Bones, 30% Shipwreck)
	var type_rng = randf()
	if type_rng < 0.7:
		obs.setup_obstacle(0) # 0 = Bones
	else:
		obs.setup_obstacle(1) # 1 = Shipwreck

	add_child(obs)
