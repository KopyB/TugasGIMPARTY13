extends Area2D

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
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
