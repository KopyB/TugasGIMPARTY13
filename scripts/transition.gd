extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect
var busy: bool = false
var ocean_handoff: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	color_rect.visible = false
	color_rect.color = Color(0.025, 0.055, 0.085, 0.0)
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP

func _input(_event: InputEvent) -> void:
	if busy:
		get_viewport().set_input_as_handled()

func load_scene(target_scene: String) -> void:
	if busy:
		return
	busy = true
	var was_paused := get_tree().paused
	get_tree().paused = true
	color_rect.show()
	var request_error := ResourceLoader.load_threaded_request(target_scene, "PackedScene")
	var fade_out := create_tween()
	fade_out.tween_property(color_rect, "color:a", 1.0, 0.22)
	await fade_out.finished
	if request_error != OK:
		await _recover_transition(was_paused, target_scene)
		return
	while ResourceLoader.load_threaded_get_status(target_scene) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
	if ResourceLoader.load_threaded_get_status(target_scene) != ResourceLoader.THREAD_LOAD_LOADED:
		await _recover_transition(was_paused, target_scene)
		return
	var packed := ResourceLoader.load_threaded_get(target_scene) as PackedScene
	if packed == null or get_tree().change_scene_to_packed(packed) != OK:
		await _recover_transition(was_paused, target_scene)
		return
	await get_tree().scene_changed
	get_tree().paused = false
	await _reveal()

func reload_scene() -> void:
	if get_tree().current_scene != null:
		load_scene(get_tree().current_scene.scene_file_path)

func _reveal() -> void:
	var fade_in := create_tween()
	fade_in.tween_property(color_rect, "color:a", 0.0, 0.22)
	await fade_in.finished
	color_rect.hide()
	busy = false

func _recover_transition(was_paused: bool, target_scene: String) -> void:
	get_tree().paused = was_paused
	push_error("Could not load scene " + target_scene)
	await _reveal()

func depart_from_menu(menu: Control) -> bool:
	if busy:
		return false
	busy = true
	var target := "res://scenes/main.tscn"
	var request_error := ResourceLoader.load_threaded_request(target, "PackedScene")
	if request_error != OK and ResourceLoader.load_threaded_get_status(target) != ResourceLoader.THREAD_LOAD_LOADED:
		busy = false
		push_error("Could not prepare gameplay")
		return false
	var departure = menu.get_node("Departure")
	await departure.play()
	while ResourceLoader.load_threaded_get_status(target) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
	if ResourceLoader.load_threaded_get_status(target) != ResourceLoader.THREAD_LOAD_LOADED:
		departure.restore()
		busy = false
		push_error("Could not load gameplay")
		return false
	var packed := ResourceLoader.load_threaded_get(target) as PackedScene
	if packed == null:
		departure.restore()
		busy = false
		return false
	# Freeze on the matched composition and capture it once for a short dissolve.
	get_tree().paused = true
	ocean_handoff = menu.get_node("BackgroundAtmosphere").call("capture_ocean_state")
	var cover: TextureRect
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var snapshot := get_viewport().get_texture().get_image()
		if snapshot != null and not snapshot.is_empty():
			cover = TextureRect.new()
			cover.texture = ImageTexture.create_from_image(snapshot)
			cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			cover.stretch_mode = TextureRect.STRETCH_SCALE
			cover.mouse_filter = Control.MOUSE_FILTER_STOP
			add_child(cover)
			cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var error := get_tree().change_scene_to_packed(packed)
	if error != OK:
		ocean_handoff.clear()
		if is_instance_valid(cover):
			cover.queue_free()
		get_tree().paused = false
		departure.restore()
		busy = false
		push_error("Could not enter gameplay")
		return false
	await get_tree().scene_changed
	if is_instance_valid(cover):
		var dissolve := create_tween()
		dissolve.tween_property(cover, "modulate:a", 0.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await dissolve.finished
		cover.queue_free()
	ocean_handoff.clear()
	get_tree().paused = false
	busy = false
	return true
