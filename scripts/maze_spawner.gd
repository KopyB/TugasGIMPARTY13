extends Node2D

var obstacle_scene = preload("res://scenes/obstacle.tscn")
var enemy_scene = preload("res://scenes/dummy.tscn") # Load scene musuh untuk spawn Shark
var parrot_scene = preload("res://scenes/parrot.tscn")

# --- CONFIG MAZE ---
var columns = 8          
var block_size = 60      
var spawn_y = -100       
var rows_to_spawn = 8      
var rows_spawned_count = 0
var maze_row_interval = 2.0
var maze_timer = 0.0

# --- CONFIG SHARK EVENT ---
var is_shark_event_active = false
var shark_timer = 0.0
var next_shark_time = 0.0
var shark_event_count = 0

# --- GLOBAL STATE ---
var is_maze_active = false 
var maze_cooldown_timer = 0.0
var next_maze_time = 45.0 
var current_gap_index = 4  

func _ready():
	add_to_group("event_manager")
	var screen_width = get_viewport_rect().size.x
	block_size = screen_width / columns
	randomize()
	
	# Waktu event pertama
	next_maze_time = get_next_maze_interval()
	next_shark_time = get_next_shark_interval()
	
	print("Next Maze: %.1f | Next Shark: %.1f" % [next_maze_time, next_shark_time])

func _process(delta):
	# Cek apakah ada event yang sedang aktif?
	var any_event_active = is_maze_active or is_shark_event_active
	
	if not any_event_active:
		
		# Hitung Timer Maze
		maze_cooldown_timer += delta
		if maze_cooldown_timer >= next_maze_time:
			start_maze_event()
			return # Prioritas: Langsung return agar tidak cek shark di frame yang sama

		# Hitung Timer Shark
		shark_timer += delta
		if shark_timer >= next_shark_time:
			start_shark_event()
			
		var chaos_chance = 1000000000000000 
		
		if GameData.is_hard_mode:
			chaos_chance = 1000000000000    
			
		if randi() % chaos_chance == 0:
			start_chaos_shark_mode()
	else:
		
		# Jika Maze aktif, jalankan logika spawn row maze
		if is_maze_active:
			maze_timer += delta
			if maze_timer >= maze_row_interval:
				maze_timer = 0
				spawn_maze_row()
		

# =========================================
#           LOGIKA SHARK ATTACK
# =========================================

func start_shark_event():
	shark_event_count += 1
	print("!!! WARNING: SHARK ATTACK EVENT STARTED (Ke-%d) !!!" % shark_event_count)
	
	is_shark_event_active = true
	shark_timer = 0.0 # Reset timer
	
	get_tree().call_group("spawner_utama", "pause_spawning")
	
	await get_tree().create_timer(2.0).timeout
	
	spawn_shark_waves()

func spawn_shark_waves():
	# Konfigurasi wave spawn:
	var min_waves = 2
	var max_waves = 4
	var min_sharks = 5
	var max_sharks = 10
		# --- HARD MODE  ---
	if shark_event_count >= 3:
		min_waves += 1   
		max_waves += 1   
		
		min_sharks += 3  
		max_sharks += 5  
		
	if GameData.is_hard_mode:
		min_sharks += 5  
		max_sharks += 10
		
	var total_waves = randi_range(min_waves, max_waves)
	print(">>> START SHARK EVENT: Total %d Waves <<<" % total_waves)
	
	for i in range(total_waves):
		if not is_inside_tree(): return 
		if shark_event_count >= 3 and randf() <= 0.10:	
			# Delay 6 - 10 detik
			var delay_time = randf_range(6.0, 10.0)
			
			get_tree().create_timer(delay_time).timeout.connect(spawn_parrot_event)
			
		var sharks_this_wave = randi_range(min_sharks, max_sharks)
		print(">>> Wave %d/%d: Spawning %d Sharks" % [i + 1, total_waves, sharks_this_wave])
		
		for j in range(sharks_this_wave):
			spawn_single_shark()
			await get_tree().create_timer(randf_range(0.25, 1.25)).timeout
		
		if i < total_waves - 1: 
			await get_tree().create_timer(randf_range(4.0, 6.0)).timeout
	
	end_shark_event()

func spawn_single_shark():
	var shark = enemy_scene.instantiate()
	shark.enemy_type = 4 # TORPEDO SHARK
	
	var viewport_rect = get_viewport_rect().size
	var spawn_pos = Vector2.ZERO
	
	# Random Spawn: Atas, Kiri, atau Kanan (Mirip EnemySpawner)
	var spawn_side = randi() % 3
	
	if spawn_side == 0: # Atas
		spawn_pos.x = randf_range(50, viewport_rect.x - 50)
		spawn_pos.y = -60
	elif spawn_side == 1: # Kiri
		spawn_pos.x = -60
		spawn_pos.y = randf_range(50, viewport_rect.y / 3)
	else: # Kanan
		spawn_pos.x = viewport_rect.x + 60
		spawn_pos.y = randf_range(50, viewport_rect.y / 3)
	
	shark.global_position = spawn_pos
	
	# PENTING: Add ke current_scene agar koordinat aman
	get_tree().current_scene.call_deferred("add_child", shark)

func end_shark_event():
	print("!!! SHARK ATTACK EVENT ENDED !!!")
	is_shark_event_active = false
	
	next_shark_time = get_next_shark_interval()
	
	get_tree().call_group("spawner_utama", "resume_spawning")

func spawn_parrot_event():
	var new_parrot = parrot_scene.instantiate()
	
	var parrot_logic = new_parrot.get_child(0).get_child(0)
	
	parrot_logic.enemy_type = 3 # Tipe 3 = PARROT
	parrot_logic.add_to_group("parrots") 
	
	new_parrot.global_position = Vector2.ZERO
	
	get_tree().current_scene.call_deferred("add_child", new_parrot)
	
# =========================================
#      LOGIKA SHARK ATTACK (HARD/CHAOS MODE)
# =========================================
func start_chaos_shark_mode():
	if is_shark_event_active or is_maze_active:
		return

	print("if that's what you want, okay...")
	is_shark_event_active = true
	shark_timer = 0.0
	
	# Pause musuh biasa
	get_tree().call_group("spawner_utama", "pause_spawning")
	
	await get_tree().create_timer(1.0, false).timeout
	
	spawn_chaos_waves()

func spawn_chaos_waves():
	var total_waves = randi_range(6, 8)  
	var sharks_per_wave = randi_range(40, 60)             
	
	print(">>> START CHAOS EVENT: %d Waves <<<" % total_waves)
	
	for i in range(total_waves):
		if not is_inside_tree(): return 
		
		print(">>> CHAOS WAVE %d/%d: RELEASE THE SWARM!" % [i + 1, total_waves])
		
		for j in range(sharks_per_wave):
			spawn_single_shark()
			if randf() <= 0.20:
				spawn_safe_parrot()
			await get_tree().create_timer(randf_range(0.10, 0.50), false).timeout
	
		if i < total_waves - 1:
			await get_tree().create_timer(3.0, false).timeout
			
	end_shark_event() 

func spawn_safe_parrot():
	var new_parrot = parrot_scene.instantiate()
	var parrot_logic = new_parrot.get_child(0).get_child(0)
	
	parrot_logic.enemy_type = 3 
	
	new_parrot.global_position = Vector2.ZERO
	get_tree().current_scene.call_deferred("add_child", new_parrot)

# =========================================
#           LOGIKA MAZE (EXISTING)
# =========================================

func start_maze_event():
	print("!!! EVENT MAZE DIMULAI !!!")
	is_maze_active = true
	rows_spawned_count = 0
	maze_cooldown_timer = 0 

	current_gap_index = randi() % (columns - 2) + 1
	get_tree().call_group("spawner_utama", "pause_spawning")

func end_maze_event():
	print("!!! EVENT MAZE SELESAI !!!")
	is_maze_active = false
	next_maze_time = get_next_maze_interval()
	get_tree().call_group("spawner_utama", "resume_spawning")

func spawn_maze_row():
	if rows_spawned_count >= rows_to_spawn:
		end_maze_event()
		return

	rows_spawned_count += 1
	var move = randi() % 3 - 1 
	if randf() < 0.2:
		move = move * 2
	
	current_gap_index += move
	current_gap_index = clamp(current_gap_index, 1, columns - 2)

	for i in range(columns):
		if i == current_gap_index or i == current_gap_index + 1:
			continue 
		if randf() > 0.3:
			spawn_obstacle_at_column(i)

func spawn_obstacle_at_column(col_index):
	var obs = obstacle_scene.instantiate()
	var pos_x = (col_index * block_size) + (block_size / 2)
	obs.position = Vector2(pos_x, spawn_y)
	obs.is_maze_obstacle = true 

	var type_rng = randf()
	if type_rng < 0.3: obs.setup_obstacle(0) 
	elif type_rng < 0.6 and type_rng >= 0.3: obs.setup_obstacle(1)
	elif  type_rng < 0.8 and type_rng >= 0.6: obs.setup_obstacle(2) 
	else: obs.setup_obstacle(3) 

	add_child(obs)

func get_next_maze_interval():
	if GameData.is_hard_mode:
		return randf_range(40.0, 45.0) 
	else:
		return randf_range(50.0, 60.0) 

func get_next_shark_interval():
	if GameData.is_hard_mode:
		return randf_range(60.0, 65.0) 
	else:
		return randf_range(70.0, 90.0) 
