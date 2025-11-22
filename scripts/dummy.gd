extends Area2D

#Beri signal saat musuh mati (BOSS EXCLUSIVE)
signal enemy_died
@onready var enemyship: Sprite2D = $enemyship
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var cannon: Sprite2D = $cannon

# TIPE MUSUH
enum Type {GUNBOAT, BOMBER}
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
var explosion_scene = preload("res://scenes/explosion.tscn")

var bomber_barrel = preload("res://assets/art/BomberWithBarrel.png")
var bomber_noBarrel = preload("res://assets/art/BomberNoBarrel.png")
var gun_boat = preload("res://assets/art/pirate gunboat base.png")

var player = null # Referensi

func _ready():
	player = get_tree().get_first_node_in_group("player")
	collision_shape_2d.disabled = false
	# Setup awal berdasarkan tipe
	if enemy_type == Type.GUNBOAT:
		enemyship.texture = gun_boat
		enemyship.position.x = -5.0
		enemyship.scale = Vector2(0.1, 0.1)
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
		
		shoot_interval = 5.0 # Drop tiap 5 detik
		speed = 150 # Kecepatan gerak ke samping
		rotation_degrees = 90 # Putar agar menghadap ke KANAN
		
func _process(delta):
	if enemy_type == Type.GUNBOAT:
		
		position.y += speed * delta
		
	elif enemy_type == Type.BOMBER:
		position.x += speed * delta

	shoot_timer += delta
	if shoot_timer >= shoot_interval:
		shoot_timer = 0
		perform_attack()
		
	# Angka 1500 dan 900 ini harus lebih besar dari ukuran layar Anda
	if position.x > 1940 or position.y > 1080: 
		queue_free()

# --- FUNGSI SERANGAN ---
func perform_attack():
	if enemy_type == Type.GUNBOAT:
		fire_gunboat()
	elif enemy_type == Type.BOMBER:
		drop_barrel()

func fire_gunboat():
	# Pastikan player masih hidup/ada
	if is_instance_valid(player):
		var bullet = bullet_scene.instantiate()
		bullet.global_position = global_position
		
		# 1. Hitung arah
		var dir = (player.global_position - global_position).normalized()
		bullet.direction = dir
		
		
		# 2. VISUAL: Suruh peluru "menatap" posisi player
		bullet.look_at(player.global_position)
		bullet.rotation_degrees += 90
		
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
	enemyship.hide()
	collision_shape_2d.disabled = true
	exploded()
	spawn_powerup_chance()
	enemy_died.emit()
	queue_free()

func spawn_powerup_chance():
	if randf() <= 0.9: 
		var powerup = powerup_scene.instantiate()
		powerup.global_position = global_position
		
		# Random angka acak 0 sampai 5 
		var random_type = randi() % 6 
		powerup.current_type = random_type
		
		get_tree().current_scene.call_deferred("add_child", powerup)

func exploded():
	var explosion = explosion_scene.instantiate()
	explosion.global_position = global_position
	get_tree().current_scene.add_child(explosion)
	
