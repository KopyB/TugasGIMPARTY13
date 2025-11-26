extends Camera2D
@onready var character_body_2d: CharacterBody2D = $"../CharacterBody2D"

@export var decay : float = 0.8
@export var max_offset : Vector2 = Vector2(100,75)
@export var max_roll : float = 0.1
@export var follow_node : Node2D

var trauma : float = 0.0
var trauma_power : int = 2

func shake() -> void:
	var amount = pow(trauma, trauma_power)
	rotation = max_roll * amount * randf_range(-1,1)
	offset.x = max_offset.x * amount * randf_range(-1,1)
	offset.y = max_offset.y * amount * randf_range(-1,1)
# Called when the node enters the scene tree for the first time.


func _ready() -> void:
	randomize()
	add_trauma(0.4)
	await get_tree().create_timer(0.3).timeout
	queue_free()

func add_trauma(amount : float) -> void:
	trauma = min(trauma + amount, 1.0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if follow_node: 
		global_position = follow_node.global_position
		
	if trauma:
		trauma = max(trauma - decay * delta, 0)
		shake()
