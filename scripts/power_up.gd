extends Area2D

@onready var crate: Sprite2D = $crate

# Daftar tipe power-up sesuai tabel Anda
enum Type {SHIELD, MULTISHOT, ARTILLERY, SPEED, KRAKEN, SECOND_WIND, ADMIRAL}

# Variabel untuk menyimpan tipe bola ini (Default Multishot)
var current_type = Type.MULTISHOT

# variabel texture crates 
var shieldcrate = preload("res://assets/art/shield/1shield box.png")
var multishotcrate = preload("res://assets/art/multi_box.png")
var artilcrate = preload("res://assets/art/burst_box.png")
var speedcrate = preload("res://assets/art/speed_box.png")
var krakencrate = preload("res://assets/art/KrakenSlayerCrate.png")
var secondwindcrate = preload("res://assets/art/secondwindcrate.png")
var admiralcrate = preload("res://assets/art/will_box.png")

func _ready():
	# Ubah warna bola berdasarkan tipe agar pemain tahu

	match current_type:
		Type.SHIELD:
			crate.texture = shieldcrate
			
		Type.MULTISHOT:
			crate.texture = multishotcrate
			
		Type.ARTILLERY:
			crate.texture = artilcrate
			
		Type.SPEED:
			crate.texture = speedcrate
			
		Type.KRAKEN:
			crate.texture = krakencrate
		Type.SECOND_WIND:
			crate.texture = secondwindcrate
		Type.ADMIRAL:
			crate.texture = admiralcrate

func _process(delta):
	position.y += 80 * delta # Kecepatan jatuh

func _on_body_entered(body):
	# Cek apakah player punya fungsi untuk menerima powerup
	if body.has_method("apply_powerup"):
		# Kirim tipe power-up ini ke player
		body.apply_powerup(current_type)
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
