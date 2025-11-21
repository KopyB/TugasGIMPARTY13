extends Marker2D

var enemy_scene = preload("res://scenes/dummy.tscn")
@onready var spawn_timer = $SpawnTimer

# --- PENGATURAN DIFFICULTY ---
var time_elapsed = 0.0     # Penghitung waktu bermain
var initial_spawn_rate = 3.0 # Awal game: Spawn tiap 3 detik
var min_spawn_rate = 0.5   # Batas ngebut: Paling cepat spawn tiap 0.5 detik
var difficulty_curve = 0.02 # Seberapa cepat game jadi susah kalau mau kesulitannya eksponensial tambahkan 0.01 + n ; n > 0

func _ready():
	# Mulai timer pertama kali
	spawn_timer.start(initial_spawn_rate)

func _process(delta):
	# Hitung durasi permainan terus menerus
	time_elapsed += delta

func _on_spawn_timer_timeout():
	spawn_linear_enemy()
	
	# --- DIFFICULTY LOGIC ---
	# Rumus: Semakin lama main (time_elapsed naik), interval spawn makin kecil
	var new_wait_time = initial_spawn_rate - (time_elapsed * difficulty_curve)
	
	# Agar tidak nol atau negatif (batas minimal 0.5 detik)
	if new_wait_time < min_spawn_rate:
		new_wait_time = min_spawn_rate
	
	# Debug print untuk melihat perubahan speed spawn
	print("Waktu main: ", int(time_elapsed), "s | Spawn Rate: ", "%.2f" % new_wait_time)
	
	# Set timer untuk spawn berikutnya dengan waktu baru
	spawn_timer.start(new_wait_time)

func spawn_linear_enemy():
	var new_enemy = enemy_scene.instantiate()
	var viewport_rect = get_viewport_rect().size
	
	# Tentukan tipe musuh berdasarkan pola (bukan random murni lagi jika mau)
	# Tapi untuk sekarang kita random tipe saja, tapi spawn-nya yang linear.
	var type_rng = randi() % 2
	
	if type_rng == 0: # GUNBOAT
		new_enemy.enemy_type = 0
		var spawn_x = randf_range(50, viewport_rect.x - 50)
		new_enemy.global_position = Vector2(spawn_x, -60)
	else: # BOMBER
		new_enemy.enemy_type = 1
		var spawn_x = -60
		var spawn_y = randf_range(50, viewport_rect.y / 3)
		new_enemy.global_position = Vector2(spawn_x, spawn_y)
	
	get_tree().current_scene.add_child(new_enemy)
