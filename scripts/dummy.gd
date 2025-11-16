extends StaticBody2D

# Atur HP musuh, bisa diubah di Inspector
@export var health: int = 67

# Fungsi ini bekerja saat bullet kena dummy
func take_damage(amount: int):
	health -= amount
	print("HIT!!")
	print("Dummy HP= ", health," /67") 

	if health <= 0:
		queue_free()
		print("Dummy died")
