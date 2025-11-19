extends Area2D

# Daftar tipe power-up sesuai tabel Anda
enum Type {SHIELD, MULTISHOT, ARTILLERY, SPEED, KRAKEN, SECOND_WIND}

# Variabel untuk menyimpan tipe bola ini (Default Multishot)
var current_type = Type.MULTISHOT

func _ready():
	# Ubah warna bola berdasarkan tipe agar pemain tahu
	match current_type:
		Type.SHIELD:
			modulate = Color.CYAN # Biru Muda
		Type.MULTISHOT:
			modulate = Color.YELLOW # Kuning
		Type.ARTILLERY:
			modulate = Color.RED # Merah
		Type.SPEED:
			modulate = Color.GREEN # Hijau
		Type.KRAKEN:
			modulate = Color.PURPLE # Ungu untuk Laser
		Type.SECOND_WIND:
			modulate = Color.WHITE # Putih suci untuk Revive

func _process(delta):
	position.y += 150 * delta # Kecepatan jatuh

func _on_body_entered(body):
	# Cek apakah player punya fungsi untuk menerima powerup
	if body.has_method("apply_powerup"):
		# Kirim tipe power-up ini ke player
		body.apply_powerup(current_type)
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
