extends Area2D

var speed = 800
var direction = Vector2.ZERO # Variabel untuk menyimpan arah

func _process(delta):
	# Bergerak sesuai arah yang sudah ditentukan (direction)
	position += direction * speed * delta

func _on_body_entered(body):
	print("Peluru Musuh nabrak: ", body.name)
	# Cek collision (kita perbaiki logika deteksinya di poin 2 nanti)
	if body.has_method("take_damage_player"):
		
		body.take_damage_player()
		queue_free()
	else: # Backup check
		#queue_free()
		pass

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
