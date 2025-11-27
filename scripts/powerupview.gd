extends CanvasLayer

@onready var scorepoint: Label = $score/scorepoint
@onready var timer: Timer = $scoretimer
@onready var icons: HBoxContainer = $icons
@onready var desc: VBoxContainer = $desc

@export var debug : bool = false
@export var desc_scene : PackedScene = preload("res://scenes/powerup_notif.tscn")
@export var icon_scene = preload("res://scenes/iconpowerup.tscn")

#preload icons
var secondwindlogo = preload("res://assets/art/Icon.png")
var krakenlogo = preload("res://assets/art/KrakenSlayerIcon.png")
var shieldlogo = preload("res://assets/art/powerup icon/2shield icon (1).png")
var admirallogo = preload("res://assets/art/powerup icon/AdmiralWillIcon.png")
var artillerylogo = preload("res://assets/art/powerup icon/ArtilleryBurstIcon.png")
var multishotlogo = preload("res://assets/art/powerup icon/MultishotIcon.png")
var speedlogo = preload("res://assets/art/powerup icon/Untitled1071_20251123144740.png")
var sirendebufflogo = preload("res://assets/art/powerup icon/Debuff icon.png")

var logo = preload("res://assets/art/Untitled1063_20251117223413.png")

var score: int = 0
var is_reset: bool = false
func _ready() -> void:
	add_to_group("ui_manager")
	start_timer_score()

func start_timer_score():
	$score.show()
	timer.timeout.connect(_on_score_timer_timeout)
	timer.start() 
	update_score_display()
	#desc.show()
	#icons.show()
	is_reset = false

func stop_timer_score():
	timer.stop()
	$score.hide()
	score = 0
	#desc.hide()
	#icons.hide()
	is_reset = true

func _on_score_timer_timeout():
	increase_score(1)

func update_score_display():
	scorepoint.text = "Score: " + str(score)

	# You can add other functions to increase score from game events if needed
func increase_score(amount: int):
	score += amount
	update_score_display()

func show_desc(message : String):
	var descs = desc_scene.instantiate()
	var tween = descs.create_tween()
	
	descs.get_child(1).text = message
	if message == "Second Wind":
		descs.get_child(0).texture = secondwindlogo
		descs.get_child(1).get_child(0).text = "This upgrade allows your ship to refuse death once and create a shockwave that clears all enemies upon revival."
	elif message == "Kraken Slayer":
		descs.get_child(0).texture = krakenlogo
		descs.get_child(1).get_child(0).text = "This upgrade allows your ship to fire a giant beam."
	elif message == "Artillery":
		descs.get_child(0).texture = artillerylogo
		descs.get_child(1).get_child(0).text = "This upgrade allows your ship increases the number of shots for a few second."
	elif message == "Multishot":
		descs.get_child(0).texture = multishotlogo
		descs.get_child(1).get_child(0).text = "This upgrade allows your ship to shoot three shots at once"
	elif message == "SPEED IS KEY":
		descs.get_child(0).texture = speedlogo
		descs.get_child(1).get_child(0).text = "This upgrade allows your ship to perform rapid left and right dodges for a short time"
	elif message == "Shield":
		descs.get_child(0).texture = shieldlogo
		descs.get_child(1).get_child(0).text = "This upgrade allows your ship to survive ONE hit from any kind of enemy fire."
	elif message == "Admiral's Will":
		descs.get_child(0).texture = admirallogo
		descs.get_child(1).get_child(0).text = "The upgrade will release a shockwave that paralyzes enemies for a brief moment."
	else: # nanti tambahin yang lain lagi, ini placeholder
		descs.get_child(0).texture = logo
	desc.add_child(descs)
	
	tween.tween_interval(2.5)
	tween.tween_callback(descs.queue_free)

	#if is_reset:
		#descs.queue_free()
	
func show_icons(message :String, duration : float):
	var allicon = icon_scene.instantiate()
	var tween = icons.create_tween()
	
	if message == "Second Wind":
		allicon.get_child(1).texture = secondwindlogo
	elif message == "Kraken Slayer":
		allicon.get_child(1).texture = krakenlogo
		allicon.get_child(0).start_countdown(duration)
	elif message == "Artillery":
		allicon.get_child(1).texture = artillerylogo
		allicon.get_child(0).start_countdown(duration)
	elif message == "Multishot":
		allicon.get_child(1).texture = multishotlogo
		allicon.get_child(0).start_countdown(duration)
	elif message == "SPEED IS KEY":
		allicon.get_child(1).texture = speedlogo
		allicon.get_child(0).start_countdown(duration)
	elif message == "Shield":
		allicon.get_child(1).texture = shieldlogo
	elif message == "Admiral's Will":
		allicon.get_child(1).texture = admirallogo
		allicon.get_child(0).start_countdown(duration)
	elif message == "Dizziness":
		allicon.get_child(1).texture = sirendebufflogo
		allicon.get_child(0).start_countdown(duration)
	else: # nanti tambahin yang lain lagi, ini placeholder
		allicon.get_child(1).texture = logo
	icons.add_child(allicon)

	tween.tween_interval(duration)
	tween.tween_callback(allicon.queue_free)
	#if is_reset:
		#icons.queue_free()
func reset_icon():
	var tempicon : HBoxContainer
	tempicon = HBoxContainer.new()
	tempicon.name = "icons"
	tempicon.global_position = icons.global_position
	tempicon.scale = icons.scale
	tempicon.size = icons.size
	icons.queue_free()
	icons = tempicon
	add_child(icons)
	
func reset_desc():
	var tempdesc : VBoxContainer
	tempdesc = VBoxContainer.new()
	tempdesc.name = "desc"
	tempdesc.global_position = desc.global_position
	tempdesc.scale = desc.scale
	tempdesc.size = desc.size
	desc.queue_free()
	desc = tempdesc
	add_child(desc)
