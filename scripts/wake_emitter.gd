extends Node2D

var previous_position: Vector2
var elapsed: float = 0.0
var actor: Node2D
var effects

func _ready() -> void:
	actor = get_parent() as Node2D
	effects = get_node("/root/VisualFX")
	previous_position = actor.global_position

func _process(delta: float) -> void:
	var distance := actor.global_position.distance_to(previous_position)
	previous_position = actor.global_position
	var trails := actor.get_node_or_null("trails") as CanvasItem
	if not effects.enabled or not actor.is_visible_in_tree() or trails == null or not trails.is_visible_in_tree():
		return
	if actor.get("is_game_over") == true or actor.get("is_dead") == true or actor.get("is_paralyzed") == true:
		return
	elapsed += delta
	if elapsed < 0.10:
		return
	elapsed = 0.0
	var motion := distance / maxf(delta, 0.001)
	var strength := clampf(0.65 + motion / 900.0, 0.65, 1.25)
	var stern := actor.to_global(Vector2(0.0, 52.0))
	effects.wake(stern, actor.global_rotation, strength)
