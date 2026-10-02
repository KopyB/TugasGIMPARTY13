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

var active_boolean_icons : Dictionary = {}
var score: int = 0
var time_elapsed: float = 0.0
var is_reset: bool = false

func _ready() -> void:
	add_to_group("ui_manager")
	icons.add_child(preload("res://scripts/siren_status.gd").new())
	start_timer_score()
	time_elapsed = 0.0

func _process(delta):
	if not timer.is_stopped():
		time_elapsed += delta
		
func get_formatted_time() -> String:
	var minutes = int(time_elapsed / 60)
	var seconds = int(time_elapsed) % 60
	return "%02d:%02d" % [minutes, seconds]
	
func start_timer_score():
	$score.show()
	if not timer.timeout.is_connected(_on_score_timer_timeout):
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
	scorepoint.text = str(score)

	# You can add other functions to increase score from game events if needed
func increase_score(amount: int):
	score += amount
	if score < 0:
		score = 0
	update_score_display()

func show_desc(message: String):
	# Keep only the newest two cards so pickups cannot cover the playfield.
	while desc.get_child_count() >= 2:
		var old := desc.get_child(0)
		desc.remove_child(old)
		old.queue_free()
	var card := preload("res://scripts/powerup_catalog.gd").make_card(message)
	desc.add_child(card)
	var tween := card.create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(card, "modulate:a", 0.0, 0.2)
	tween.tween_callback(card.queue_free)

func show_icons(message :String, duration : float):
	if message == "Dizziness":
		return # The live status card handles duration refresh and pause correctly.
	if message == "Shield" or message == "Second Wind":
		var is_active = duration > 0 
		
		if is_active:
			if active_boolean_icons.has(message):
				return 
			var icon_instance = icon_scene.instantiate()
			if message == "Second Wind":
				icon_instance.get_child(1).texture = secondwindlogo
			elif message == "Shield":
				icon_instance.get_child(1).texture = shieldlogo
			
			icon_instance.get_child(0).max_value = 100
			icon_instance.get_child(0).value = 100
			icon_instance.get_child(0).stop_countdown()
			icons.add_child(icon_instance)
			active_boolean_icons[message] = icon_instance
			
		else:
			if active_boolean_icons.has(message):
				var node_to_delete = active_boolean_icons[message]
				node_to_delete.queue_free()
				active_boolean_icons.erase(message)
		return
	
	var allicon = icon_scene.instantiate()
	icons.add_child(allicon)
	var tween = allicon.create_tween()
	
	if message == "Kraken Slayer":
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
	elif message == "Admiral's Will":
		allicon.get_child(1).texture = admirallogo
		allicon.get_child(0).start_countdown(duration)
	elif message == "Dizziness":
		allicon.get_child(1).texture = sirendebufflogo
		allicon.get_child(0).start_countdown(duration)
	else: # nanti tambahin yang lain lagi, ini placeholder
		allicon.get_child(1).texture = logo

	tween.tween_interval(duration)
	tween.tween_callback(allicon.queue_free)
	#if is_reset:
		#icons.queue_free()
func reset_icon():
	active_boolean_icons.clear()
	for child in icons.get_children():
		icons.remove_child(child)
		child.queue_free()
	icons.add_child(preload("res://scripts/siren_status.gd").new())

func reset_desc():
	for child in desc.get_children():
		desc.remove_child(child)
		child.queue_free()
