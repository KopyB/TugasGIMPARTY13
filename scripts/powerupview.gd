extends CanvasLayer

@onready var scorepoint: Label = $score/scorepoint
@onready var timer: Timer = $Timer

var score: int = 0

func _ready():
	# Connect the Timer's timeout signal to our function
	timer.timeout.connect(_on_score_timer_timeout)
	# If Autostart is false, you can start the timer here:
	# score_timer.start() 
	update_score_display()

func _on_score_timer_timeout():
	score += 1
	update_score_display()

func update_score_display():
	scorepoint.text = "Score: " + str(score)

	# You can add other functions to increase score from game events if needed
func increase_score(amount: int):
	score += amount
	update_score_display()
