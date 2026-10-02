extends Node

const PACING = preload("res://scripts/voyage_pacing.gd")
## Visual-only flight. No player controller or combat timers run in this scene.
const WORLD_OFFSET := Vector2(0, 2040)
const FINAL_CAMERA := Vector2(960, 540)
const FINAL_SHIP := Vector2(971, 944)
const FOLLOW_DURATION := 1.25
var menu: Control
var camera: Camera2D
var ship: Node2D
var preview: Node2D
var departure_water: Node2D
var wake_elapsed := 0.0
var wake_active := false
var ocean
var original_position: Vector2
var original_ship_position: Vector2
var original_sprite_offset: Vector2
var original_scroll := 0.0
var original_base_offset := Vector2.ZERO
var faded: Array[CanvasItem] = []
var initial_colors: Array[Color] = []
var follow_ship_start := Vector2.ZERO
var follow_camera_start := Vector2.ZERO

func play() -> void:
	menu = get_parent() as Control
	ocean = menu.get_node("BackgroundAtmosphere")
	ship = menu.get_node("animationstella") as Node2D
	original_position = menu.position
	original_ship_position = ship.position
	original_sprite_offset = menu.get_node("animationstella/Sprite2D").offset
	menu.get_node("animationstella/Sprite2D").offset = Vector2(53, -0.5)
	original_scroll = ocean.ocean_scroll
	original_base_offset = ocean.scroll_base_offset
	menu.get_node("animationstella/AnimationPlayer").stop()
	menu.position += WORLD_OFFSET
	camera = Camera2D.new()
	menu.add_child(camera)
	camera.global_position = FINAL_CAMERA + WORLD_OFFSET
	camera.zoom = get_viewport().get_visible_rect().size / Vector2(1920, 1080)
	camera.make_current()
	camera.force_update_scroll()
	# Rebase both scene and sea together, avoiding a visible first-frame jump.
	ocean.ocean_scroll = fposmod(ocean.ocean_scroll + WORLD_OFFSET.y, 1080.0)
	ocean.scroll_base_offset.y += WORLD_OFFSET.y
	ship.global_position = Vector2(FINAL_SHIP.x, WORLD_OFFSET.y + 1260)
	ship.show()
	menu.get_node("animationstella/Sprite2D").modulate = Color.WHITE
	menu.get_node("animationstella/wavestransition").play()
	for name in ["mainbuttons", "DifficultyPanel", "HighScoreLabel", "logo", "CopalGimming"]:
		var item := menu.get_node_or_null(NodePath(name)) as CanvasItem
		if item != null:
			faded.append(item)
			initial_colors.append(item.modulate)
			var fade := create_tween()
			fade.tween_property(item, "modulate:a", 0.0, 0.2)
	_build_ship_preview()
	wake_active = true
	var launch := create_tween()
	launch.tween_method(_launch, ship.global_position.y, WORLD_OFFSET.y + 320.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await launch.finished
	follow_ship_start = ship.global_position
	follow_camera_start = camera.global_position
	var follow := create_tween()
	follow.tween_method(_follow, 0.0, 1.0, FOLLOW_DURATION)
	follow.parallel().tween_property(ocean, "scroll_speed", PACING.current_speed(GameData.is_hard_mode), FOLLOW_DURATION)
	await follow.finished
	_follow(1.0)
	camera.force_update_scroll()
	ocean.call("_process", 0.0)

func _launch(y: float) -> void:
	ship.global_position.y = y
	preview.global_position = ship.global_position
	departure_water.global_position = ship.global_position

func _follow(t: float) -> void:
	var smooth := t * t * (3.0 - 2.0 * t)
	camera.global_position = follow_camera_start.lerp(FINAL_CAMERA, smooth)
	# Preserve launch velocity, then settle at the gameplay spawn with zero speed.
	var h00 := 2.0 * t * t * t - 3.0 * t * t + 1.0
	var h10 := t * t * t - 2.0 * t * t + t
	var h01 := -2.0 * t * t * t + 3.0 * t * t
	ship.global_position = follow_ship_start * h00 + Vector2(0, -1880.0 * FOLLOW_DURATION) * h10 + FINAL_SHIP * h01
	preview.global_position = ship.global_position
	departure_water.global_position = ship.global_position
	var blend := smoothstep(0.60, 0.92, t)
	preview.modulate.a = blend
	menu.get_node("animationstella/Sprite2D").modulate.a = 1.0 - blend

func _build_ship_preview() -> void:
	# Extract only visual nodes before the player scene ever enters the tree.
	var source := preload("res://scenes/player.tscn").instantiate()
	preview = Node2D.new()
	preview.name = "DepartureShipPreview"
	menu.add_child(preview)
	preview.top_level = true
	preview.transform = Transform2D.IDENTITY
	preview.z_index = 10
	preview.modulate.a = 0.0
	preview.global_position = ship.global_position
	departure_water = Node2D.new()
	departure_water.name = "DepartureWater"
	menu.add_child(departure_water)
	departure_water.top_level = true
	departure_water.global_transform = Transform2D(0.0, ship.global_position)
	departure_water.z_index = -1
	menu.get_node("animationstella/Sprite2D").light_mask = 2
	VisualFX.register_weather_sprite(menu.get_node("animationstella/Sprite2D"))
	for name in ["shadow", "trails", "shipbase", "cannon", "stellarist"]:
		var art := source.get_node(NodePath(name)) as Node2D
		art.owner = null
		for child in art.find_children("*", "", true, false):
			child.owner = null
		source.remove_child(art)
		if name == "trails":
			departure_water.add_child(art)
			VisualFX.register_animation(art, "foam")
		else:
			preview.add_child(art)
			if art is CanvasItem:
				art.light_mask = 2
				if name != "shadow":
					VisualFX.register_weather_sprite(art)
					if name in ["shipbase", "cannon"]:
						VisualFX.register_normal_trial(art)
		art.show()
		if art is AnimatedSprite2D:
			art.play("trailvert_up" if name == "trails" else "idle")
	source.free()

func restore() -> void:
	wake_active = false
	StormFX.reset_menu()
	if is_instance_valid(departure_water):
		departure_water.queue_free()
	menu.position = original_position
	ship.position = original_ship_position
	menu.get_node("animationstella/Sprite2D").offset = original_sprite_offset
	menu.get_node("animationstella/Sprite2D").modulate = Color.WHITE
	menu.get_node("animationstella/wavestransition").stop()
	ocean.ocean_scroll = original_scroll
	ocean.scroll_base_offset = original_base_offset
	ocean.scroll_speed = 60.0
	for index in range(faded.size()):
		faded[index].modulate = initial_colors[index]
	faded.clear()
	initial_colors.clear()
	if is_instance_valid(preview):
		preview.queue_free()
	if is_instance_valid(camera):
		camera.enabled = false
		camera.queue_free()
	get_viewport().canvas_transform = Transform2D.IDENTITY
	ocean.call("_process", 0.0)

func _process(delta: float) -> void:
	if not wake_active or not is_instance_valid(ship):
		return
	preview.global_position = ship.global_position
	departure_water.global_position = ship.global_position
	wake_elapsed += delta
	if wake_elapsed >= 0.055:
		wake_elapsed = 0.0
		VisualFX.wake(ship.global_position + Vector2(0, 65), 0.0, 1.3, ocean.scroll_speed)
