extends Control

@export var state: Label
@export var resume_button: Button
@onready var scorelabel: Label = $VBoxContainer/scorelabel
@onready var timer: Timer = $Timer
var score: int = 0
#signal end_screen_toggled(type: int)

const MAP_TYPE_STRING = {0: "YOU DIED!", 1: "PAUSED"}

func paused():
	get_tree().paused = true
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
func resume():
	get_tree().paused = false
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _ready() -> void:
	timer.timeout.connect(_on_score_timer_timeout)
	update_score_display()
	hide()

func _on_resume_pressed() -> void:
	resume()
	
func _on_restart_pressed() -> void:
	resume()
	Transition.reload_scene()
	#get_tree().reload_current_scene()

func _on_exit_pressed() -> void:
	resume()
	Transition.load_scene("res://scenes/main_menu.tscn")
	#get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("escape") and not get_tree().paused:
		toggled_handler(1) #masukin var baru buat klo mati atau tidak
		paused()
	elif Input.is_action_just_pressed("escape") and get_tree().paused:
		resume()

func health(health_value: int) -> void:
	pass # nanti masukin fungsinya, hasilnya buat ngubah toggled_handler typenya jadi 0

func toggled_handler(type: int) -> void:
	state.text = MAP_TYPE_STRING[type]
	if type == 0:
		resume_button.hide()
		scorelabel.show()
	else:
		resume_button.show()
		scorelabel.hide()
		
func _on_score_timer_timeout():
	score += 1
	update_score_display()

func update_score_display():
	scorelabel.text = "Score: " + str(score)

	# You can add other functions to increase score from game events if needed
func increase_score(amount: int):
	score += amount
	update_score_display()
