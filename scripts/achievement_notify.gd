extends CanvasLayer

@onready var panel = $PanelContainer 
@onready var label = $PanelContainer/HBoxContainer/Label
@onready var anim = $AnimationPlayer

func show_achievement(title: String):
	label.text = "UNLOCKED:\n" + title
	anim.play("slide_in")
