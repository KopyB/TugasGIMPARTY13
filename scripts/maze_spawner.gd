extends Node2D

var obstacle_scene = preload("res://scenes/Obstacle.tscn")

# --- KONFIGURASI MAZE ---
var columns = 8
var block_size = 60
var spawn_y = -100

# Event Settings
var rows_to_spawn = 8      # REQUEST: Hanya 8 baris
var rows_spawned_count = 0
var is_spawning = false

# Timer Interval Antar Baris Maze (Cepat/Lambatnya maze turun)
var maze_row_interval = 2.0 
var maze_timer = 0.0

# Timer "Rare" (Seberapa jarang Event Maze terjadi)
# Misal: Tiap 20 sampai 40 detik sekali baru muncul maze
var cooldown_timer = 0.0
var next_event_time = 15.0 

var current_gap_index = 4 

func _ready():
	var screen_width = get_viewport_rect().size.x
	block_size = screen_width / columns
	randomize()
	# Set waktu event pertama
	next_event_time = randf_range(15.0, 30.0)

func _process(delta):
	# LOGIKA 1: MENUNGGU WAKTU EVENT (COOLDOWN)
	if not is_spawning:
		cooldown_timer += delta
		if cooldown_timer >= next_event_time:
			start_maze_event()
	
	# LOGIKA 2: SEDANG GENERATE MAZE (8 BARIS)
	else:
		maze_timer += delta
		if maze_timer >= maze_row_interval:
			maze_timer = 0
			spawn_maze_row()

func start_maze_event():
	is_spawning = true
	rows_spawned_count = 0
	current_gap_index = randi() % (columns - 2) + 1
	
	# REQUEST 3: Matikan musuh biasa saat maze jalan
	# Kita panggil EnemySpawner lewat group atau path
	# Asumsi EnemySpawner ada di root scene main
	var enemy_spawner = get_tree().current_scene.get_node_or_null("EnemySpawner")
	if enemy_spawner and enemy_spawner.has_method("pause_spawning"):
		enemy_spawner.pause_spawning()

func end_maze_event():
	is_spawning = false
	cooldown_timer = 0
	# Reset waktu untuk event berikutnya (Rarely)
	next_event_time = randf_range(30.0, 50.0) 
	
	# REQUEST 3: Nyalakan musuh biasa lagi
	var enemy_spawner = get_tree().current_scene.get_node_or_null("EnemySpawner")
	if enemy_spawner and enemy_spawner.has_method("resume_spawning"):
		enemy_spawner.resume_spawning()

func spawn_maze_row():
	# Cek apakah sudah mencapai limit 8 baris
	if rows_spawned_count >= rows_to_spawn:
		end_maze_event()
		return

	rows_spawned_count += 1
	
	# Algoritma Winding Path (sama seperti sebelumnya)
	var move = randi() % 3 - 1
	current_gap_index += move
	current_gap_index = clamp(current_gap_index, 1, columns - 2)
	
	for i in range(columns):
		if i == current_gap_index or i == current_gap_index + 1:
			continue 
		
		# Chance spawn obstacle 70%
		if randf() > 0.3:
			spawn_obstacle_at_column(i)

func spawn_obstacle_at_column(col_index):
	var obs = obstacle_scene.instantiate()
	var pos_x = (col_index * block_size) + (block_size / 2)
	obs.position = Vector2(pos_x, spawn_y)
	
	var type = randi() % 2
	obs.setup_obstacle(type) # Setup tipe dan spawn musuh (di langkah 3)
	
	add_child(obs)
