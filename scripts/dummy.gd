extends Area2D

#Beri signal saat musuh mati (BOSS EXCLUSIVE)
signal enemy_died

# TIPE MUSUH
enum Type {GUNBOAT, BOMBER,RBOMBER}
@export var enemy_type = Type.GUNBOAT

# STATISTIK
var speed = 100
var health = 3
var shoot_timer = 0.0
var shoot_interval = 2.0 # Default Gunboat (2 detik)

# LOAD ASSET 
var powerup_scene = preload("res://scenes/power_up.tscn")
var bullet_scene = preload("res://scenes/bulletenemy.tscn")
var barrel_scene = preload("res://scenes/barrelbomb.tscn")

var player = null # Referensi

func _ready():
	player = get_tree().get_first_node_in_group("player")
	
	# Setup awal berdasarkan tipe
	if enemy_type == Type.GUNBOAT:
		# $Sprite2D.texture = gunboat_texture
		shoot_interval = 2.0 # Tembak tiap 2 detik
		rotation_degrees = 180 # Hadap bawah (visual)
		
	elif enemy_type == Type.BOMBER:
		# $Sprite2D.texture = bomber_texture
		shoot_interval = randf_range(2.5, 5.0) # Drop interval random range dari 2.5 - 5 detik (biar g gitu2 doang patternnya - kaiser)
		speed = 150 # Kecepatan gerak ke samping
		rotation_degrees = 90 # Putar agar menghadap ke KANAN
		
	elif enemy_type == Type.RBOMBER:
		# $Sprite2D.texture = bomber_texture
		shoot_interval = randf_range(2.5, 5.0) # Drop interval random range dari 2.5 - 5 detik (biar g gitu2 doang patternnya - kaiser)
		speed = 150 # Kecepatan gerak ke samping
		rotation_degrees = -90 # Putar agar menghadap ke KIRI
		
func _process(delta):
	if enemy_type == Type.GUNBOAT:
		
		position.y += speed * delta
		
	elif enemy_type == Type.BOMBER:
		position.x += speed * delta
	
	elif enemy_type == Type.RBOMBER:
		position.x -= speed * delta
		
	shoot_timer += delta
	if shoot_timer >= shoot_interval:
		shoot_timer = 0
		perform_attack()
		
	# Angka 1500 dan 900 ini harus lebih besar dari ukuran layar Anda
	if (position.x > 1940 or position.y > 1080) and not enemy_type == Type.RBOMBER: 
		queue_free()
	elif enemy_type == Type.RBOMBER: #supaya RBOMBER tidak langsung despawn -kaiser
		if position.x < -20 or position.y > 1080:
			queue_free()

# --- FUNGSI SERANGAN ---
func perform_attack():
	if enemy_type == Type.GUNBOAT:
		fire_gunboat()
	elif enemy_type == Type.BOMBER or Type.RBOMBER:
		drop_barrel()

func fire_gunboat():
	if is_instance_valid(player):
		
		# Jika Y Musuh > Y Player, artinya Musuh ada DI BAWAH (di belakang) Player.
		# Beri toleransi sedikit (10 pixel)
		if global_position.y >= player.global_position.y - 10:
			return 
			
		var bullet = bullet_scene.instantiate()
		bullet.global_position = global_position
		
		var dir = (player.global_position - global_position).normalized()
		bullet.direction = dir
		bullet.look_at(player.global_position)
		
		get_tree().current_scene.add_child(bullet)
		
func drop_barrel():
	var barrel = barrel_scene.instantiate()
	barrel.global_position = global_position
	get_tree().current_scene.add_child(barrel)
	
	# Opsional: Ubah sprite musuh jadi "kosong" sebentar (Visual Direction)
	# $Sprite2D.texture = load("res://assets/bomber_empty.png")

# --- LOGIKA TABRAKAN (KAMIKAZE) ---
func _on_body_entered(body):
	if body.has_method("take_damage_player"):
		print("KENA PLAYER! PLAYER HARUSNYA MATI.")
		body.take_damage_player()
		die() 

# --- LOGIKA TERIMA DAMAGE & MATI ---
func take_damage(amount):
	health -= amount
	if health <= 0:
		die()

func die():
	spawn_powerup_chance()
	enemy_died.emit()
	if enemy_type == Type.BOMBER or Type.RBOMBER:
		drop_barrel()
	queue_free()

func spawn_powerup_chance():
	if randf() <= 0.5: 
		var powerup = powerup_scene.instantiate()
		powerup.global_position = global_position
		
		# Random angka acak 0 sampai 5 
		var random_type = randi() % 6 
		powerup.current_type = random_type
		
		get_tree().current_scene.call_deferred("add_child", powerup)
