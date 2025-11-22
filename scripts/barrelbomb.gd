extends Area2D

var fall_speed = 150 #tadi beda sm fall speed power up - kaiser 
var damage = 1

func _ready():
	add_to_group("enemy_projectiles")
	
func _process(delta):
	position.y += fall_speed * delta

func _on_body_entered(body):
	if body.has_method("take_damage_player"):
		body.take_damage_player()
		meledak()

# Logika Kena Tembak 
func take_damage(amount):
	meledak()

func meledak():
	# Spawn efek ledakan disini nanti
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
