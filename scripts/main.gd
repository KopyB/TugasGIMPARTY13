extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Powerupview.stop_timer_score()
	Powerupview.start_timer_score()# Replace with function body.
	$tutoriallayer/AnimationPlayer.play("tutorialfade")
