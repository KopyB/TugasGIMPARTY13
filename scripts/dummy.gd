extends Area2D

#Beri signal saat musuh mati (BOSS EXCLUSIVE)
signal enemy_died

# TIPE MUSUH
enum Type {GUNBOAT, BOMBER,RBOMBER, TORPEDO_SHARK}
@export var enemy_type = Type.GUNBOAT

# STATISTIK
var speed = 100
var health = 3
var shoot_timer = 0.0
var shoot_interval = 2.0 # Default Gunboat (2 detik)

var is_paralyzed = false

# --- SHARK VARIABLE ---
var shark_timer = 0.0
var shark_lock_duration = 5.0 # Locks on 5 sec
var is_shark_charging = false
var shark_charge_direction = Vector2.ZERO
var shark_charge_speed = 1000.0 

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
	
	elif enemy_type == Type.TORPEDO_SHARK:
		health = 3 # Agak tebal sedikit
		speed = 50 # Gerak pelan saat fase aiming
		
func _process(delta):
	if is_paralyzed:
		return
		
	if enemy_type == Type.GUNBOAT:
		
		position.y += speed * delta
		
	elif enemy_type == Type.BOMBER:
		position.x += speed * delta
	
	elif enemy_type == Type.RBOMBER:
		position.x -= speed * delta
	
	elif enemy_type == Type.TORPEDO_SHARK:
		handle_shark_behavior(delta)
	
	if enemy_type != Type.TORPEDO_SHARK:
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

# --- FUNGSI PARALYZED ---
func set_paralyzed(status):
	is_paralyzed = status
	if is_paralyzed:
		modulate = Color(0.5, 0.5, 0.5, 1) 
	else:
		modulate = Color.WHITE
		
# --- FUNGSI SERANGAN ---
func perform_attack():
	if enemy_type == Type.GUNBOAT:
		fire_gunboat()
	elif enemy_type == Type.BOMBER or enemy_type == Type.RBOMBER:
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
	get_tree().current_scene.call_deferred("add_child", barrel)
	
	# Opsional: Ubah sprite musuh jadi "kosong" sebentar (Visual Direction)
	# $Sprite2D.texture = load("res://assets/bomber_empty.png")

# --- LOGIKA TABRAKAN (KAMIKAZE) ---
func _on_body_entered(body):
	if body.has_method("take_damage_player"):
		body.take_damage_player()
		die() 
		
# --- FUNGSI KHUSUS PERILAKU SHARK ---
func handle_shark_behavior(delta):
	if not is_shark_charging:
		# FASE 1: LOCKING ON (5 Detik)
		shark_timer += delta
		
		if is_instance_valid(player):
			# Selalu menatap player (Lock on visual)
			look_at(player.global_position)
		
		# Bergerak maju pelan-pelan 
		position += Vector2.RIGHT.rotated(rotation) * speed * delta
		
		# Cek waktu lock habis
		if shark_timer >= shark_lock_duration:
			start_shark_charge()
	else:
		# FASE 2: CHARGING (Lurus terus)
		position += shark_charge_direction * shark_charge_speed * delta

func start_shark_charge():
	is_shark_charging = true
	# Kunci arah saat ini (berdasarkan rotasi terakhir ke player)
	shark_charge_direction = Vector2.RIGHT.rotated(rotation)
	
	# Visual Feedback: Ubah warna jadi Merah (Tanda bahaya & Kebal)
	modulate = Color(10, 0, 0, 1) # Merah menyala
	print("SHARK CHARGING! IMMUNE ACTIVATED!")
	
# --- LOGIKA TERIMA DAMAGE & MATI ---
func take_damage(amount):
	if enemy_type == Type.TORPEDO_SHARK and is_shark_charging:
		return # NO DAMAGE
		
	health -= amount
	if health <= 0:
		die()

func die():
	spawn_powerup_chance()
	enemy_died.emit()
	if enemy_type == Type.BOMBER or enemy_type == Type.RBOMBER:
		drop_barrel()
	queue_free()

func spawn_powerup_chance():
	if randf() <= 0.75: 
		var powerup = powerup_scene.instantiate()
		powerup.global_position = global_position
		
		# Random angka acak 0 sampai 6
		var random_type = randi() % 7 
		powerup.current_type = random_type
		
		get_tree().current_scene.call_deferred("add_child", powerup)
