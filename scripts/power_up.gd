extends Area2D

@onready var krakencrate: Sprite2D = $krakencrate
@onready var secondwind: Sprite2D = $secondwindcrate

# Daftar tipe power-up sesuai tabel Anda
enum Type {SHIELD, MULTISHOT, ARTILLERY, SPEED, KRAKEN, SECOND_WIND, ADMIRAL}

# Variabel untuk menyimpan tipe bola ini (Default Multishot)
var current_type = Type.MULTISHOT

func _ready():
	# Ubah warna bola berdasarkan tipe agar pemain tahu
	krakencrate.hide()
	match current_type:
		Type.SHIELD:
			modulate = Color.CYAN # Biru Muda
			krakencrate.hide()
			secondwind.hide()
		Type.MULTISHOT:
			modulate = Color.YELLOW # Kuning
			krakencrate.hide()
			secondwind.hide()
		Type.ARTILLERY:
			modulate = Color.RED # Merah
			krakencrate.hide()
			secondwind.hide()
		Type.SPEED:
			modulate = Color.GREEN # Hijau
			krakencrate.hide()
			secondwind.hide()
		Type.KRAKEN:
			krakencrate.show()
			secondwind.hide()
		Type.SECOND_WIND:
			krakencrate.hide()
			secondwind.show()
		Type.ADMIRAL:
			modulate = Color.WHITE # Putih 
			krakencrate.hide()
			secondwind.hide()

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
