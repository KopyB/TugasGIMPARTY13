extends Marker2D

var enemy_scene = preload("res://scenes/dummy.tscn")
@onready var spawn_timer = $SpawnTimer

# --- SETTING DIFFICULTY ---
var time_elapsed = 0.0
var initial_spawn_rate = 8.0 # Awal game 8 detik
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
	var type_rng = randf() #biar bisa diatur conditional sm chance masing2 enemy type - kaiser
	
	
	
	if type_rng < 0.7: #chance gunboat lebih sering, jdi 70% - kaiser
		# --- GUNBOAT (Spawn Berkelompok 1-3) ---
		var group_count = randi_range(1, 3) # Random 1 sampai 3 kapal
		
		
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
			
	else:
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
