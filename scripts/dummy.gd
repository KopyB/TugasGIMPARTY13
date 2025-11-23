extends Area2D

#Beri signal saat musuh mati (BOSS EXCLUSIVE)
signal enemy_died
@onready var enemyship: Sprite2D = $enemyship
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var cannon: Sprite2D = $cannon

# TIPE MUSUH
enum Type {GUNBOAT, BOMBER, RBOMBER, PARROT, TORPEDO_SHARK, SIREN, RSIREN}
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

# --- SIREN VARIABLE ---
var is_diving = false
var is_screaming = false

# LOAD ASSET 
var powerup_scene = preload("res://scenes/power_up.tscn")
var bullet_scene = preload("res://scenes/bulletenemy.tscn")
var barrel_scene = preload("res://scenes/barrelbomb.tscn")
var explosion_scene = preload("res://scenes/explosion.tscn")
var bomber_barrel = preload("res://assets/art/BomberWithBarrel.png")
var bomber_noBarrel = preload("res://assets/art/BomberNoBarrel.png")
var gun_boat = preload("res://assets/art/pirate gunboat base.png")
var siren = preload("res://assets/art/siren(temp).png")
@onready var taunt = $parrot_taunt
@onready var pdeath = $parrot_spawn

var player = null # Referensi

func _ready():
	player = get_tree().get_first_node_in_group("player")
	collision_shape_2d.disabled = false
	# Setup awal berdasarkan tipe
	if enemy_type == Type.GUNBOAT:
		enemyship.texture = gun_boat
		enemyship.position.x = -5.0
		enemyship.scale = Vector2(0.06, 0.06)
		cannon.show()
		
		collision_shape_2d.shape.extents = Vector2(284.0/2, 116.0/2)
		
		shoot_interval = 2.0 # Tembak tiap 2 detik
		rotation_degrees = 180 # Hadap bawah (visual)
		
	elif enemy_type == Type.BOMBER:
		cannon.hide()
		enemyship.texture = bomber_barrel
		enemyship.rotation = -PI/2
		enemyship.scale = Vector2(0.15, 0.15)
		
		collision_shape_2d.shape.extents = Vector2(280.0/2, 145.0/2)

		shoot_interval = randf_range(2.5, 5.0) # Drop interval random range dari 2.5 - 5 detik (biar g gitu2 doang patternnya - kaiser)
		speed = 150 # Kecepatan gerak ke samping
		rotation_degrees = 90 # Putar agar menghadap ke KANAN
		
	elif enemy_type == Type.RBOMBER:
		cannon.hide() 
		enemyship.texture = bomber_barrel 
		enemyship.scale = Vector2(0.15, -0.15)
		enemyship.rotation = -PI/2 
		
		shoot_interval = randf_range(2.5, 5.0) 
		speed = 150 
		rotation_degrees = -90 # Menghadap Kiri
	
	elif enemy_type == Type.TORPEDO_SHARK:
		health = 3 # Agak tebal sedikit
		speed = 50 # Gerak pelan saat fase aiming
	
		
	elif enemy_type == Type.SIREN:
		cannon.hide()
		enemyship.texture = siren
		enemyship.scale = Vector2(0.2, 0.2)
		rotation_degrees = -90
		speed = 120
	
	elif enemy_type == Type.RSIREN:
		cannon.hide()
		enemyship.texture = siren
		enemyship.scale = Vector2(0.2, 0.2)
		rotation_degrees = 90
		speed = 120
		

		
	elif enemy_type == Type.PARROT:
		print("Parrot spawned")
		
func _process(delta):
	if is_paralyzed:
		if enemy_type == Type.GUNBOAT:
			position.y += speed/2 * delta
		elif enemy_type == Type.BOMBER or enemy_type == Type.RBOMBER:
			position.y += speed * delta
		return
		
	if enemy_type == Type.GUNBOAT:
		position.y += speed * delta
		
	elif enemy_type == Type.BOMBER:
		position.x += speed * delta
	
	elif enemy_type == Type.RBOMBER:
		position.x -= speed * delta
	
	elif enemy_type == Type.TORPEDO_SHARK:
		handle_shark_behavior(delta)

	elif enemy_type == Type.SIREN:
		if not is_screaming:	
			position.x += speed * delta
		handle_diving(delta)
	
	elif enemy_type == Type.RSIREN:
		if not is_screaming:
			position.x -= speed * delta
		handle_diving(delta)
	
	if enemy_type != Type.TORPEDO_SHARK and enemy_type != Type.SIREN and enemy_type != Type.RSIREN:
		shoot_timer += delta
		if shoot_timer >= shoot_interval:
			shoot_timer = 0
			perform_attack()
			
	check_despawn()

# --- FUNGSI DESPAWN ---
func check_despawn():
	var viewport_width = get_viewport_rect().size.x
	var viewport_height = get_viewport_rect().size.y

	if (position.x > viewport_width + 20 or position.y > viewport_height + 100) and not (enemy_type == Type.RBOMBER or enemy_type == Type.RSIREN):
		queue_free()

	elif enemy_type == Type.RBOMBER or enemy_type == Type.RSIREN:
		if position.x < -20 or position.y > viewport_height + 100:
			queue_free()

# --- FUNGSI DIVING (SIREN) ---
func handle_diving(delta):
	if is_diving:
		modulate.a -= 2.0 * delta
		if modulate.a <= 0:
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

func trigger_siren_scream():
	if is_screaming:
		return
	if is_diving:
		return
	
	is_screaming = true
	modulate = Color(1, 0, 1, 1)
	print("SIREN SCREAM! PLAYER DIZZYY!")

	if is_instance_valid(player) and player.has_method("apply_dizziness"):
		player.apply_dizziness(4.0)

	await get_tree().create_timer(1.5).timeout
	is_diving = true

# --- LOGIKA TERIMA DAMAGE & MATI ---
func take_damage(amount):
	var parrotcheck = get_tree().get_nodes_in_group("parrots").size()
	if not enemy_type == Type.PARROT:
		if parrotcheck == 0:
			if enemy_type == Type.TORPEDO_SHARK and is_shark_charging:
				return # NO DAMAGE
			health -= amount
			if health <= 0:
				die()
		else:
			taunt.play()
			
		
		if enemy_type == Type.SIREN or enemy_type == Type.RSIREN:
			trigger_siren_scream()
			return
	else:
		health -= amount
		if health <= 0:
			pdeath.play()
			die()

func die():
	if not enemy_type == Type.PARROT:
		enemyship.hide()
		collision_shape_2d.disabled = true
		exploded()
		spawn_powerup_chance()
		enemy_died.emit()
	if enemy_type == Type.BOMBER or enemy_type == Type.RBOMBER:
		drop_barrel()
		queue_free()
	else:
		remove_from_group("parrots")
		spawn_powerup()
		queue_free()
	print("Parrots alive: ", get_tree().get_nodes_in_group("parrots").size())

func spawn_powerup_chance():
	if randf() <= 0.25: 
		spawn_powerup()

func spawn_powerup():
	var powerup = powerup_scene.instantiate()
	powerup.global_position = global_position
	
	# Random angka acak 0 sampai 6
	var random_type = randi() % 7 
	powerup.current_type = random_type
	
	get_tree().current_scene.call_deferred("add_child", powerup)
		
func exploded():
	var explosion = explosion_scene.instantiate()
	explosion.global_position = global_position
	get_tree().current_scene.add_child(explosion)
	
