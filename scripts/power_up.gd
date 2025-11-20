extends Area2D

<<<<<<< Updated upstream
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

=======
var speed = 150

func _process(delta):
	position.y += speed * delta # Bergerak turun agar bisa dikejar player

# Hubungkan sinyal "body_entered" milik Area2D ini ke script ini
func _on_body_entered(body):
	# Cek apakah yang nabrak adalah Player (nama class atau nama node)
	# Pastikan script player punya nama class, atau cek nama node "CharacterBody2D"
	if body.name == "CharacterBody2D" or body.has_method("activate_multishot"):
		body.activate_multishot() # Panggil fungsi di player
		queue_free() # Hapus bola ini

# Opsional: Hapus jika keluar layar (gunakan VisibleOnScreenNotifier2D seperti peluru)
>>>>>>> Stashed changes
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
