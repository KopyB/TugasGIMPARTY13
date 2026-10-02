extends Node2D
## Visual-only fixtures. Player/enemy controllers never enter the tree.
const PLAYER = preload("res://scenes/player.tscn")
const ENEMY = preload("res://scenes/dummy.tscn")
const BARREL = preload("res://scenes/barrelbomb.tscn")
const EXPLOSION = preload("res://scenes/explosion.tscn")
const PULSE = preload("res://scripts/visual_pulse.gd")
var elapsed := 0.0
var next_flash := 0.8
var moving_light := false
var exiting := false
var sweep_lights: Array[PointLight2D] = []
var pose_sprites: Array[AnimatedSprite2D] = []
var subjects: Array[Node2D] = []
var right_title: Label
var normal_button: Button
var sweep_button: Button

func _ready() -> void:
	StormFX.reset_menu()
	var ocean := preload("res://scenes/menu_ocean.tscn").instantiate()
	add_child(ocean)
	ocean.scroll_speed = 25.0
	var camera := Camera2D.new()
	add_child(camera)
	camera.position = Vector2(960, 540)
	camera.zoom = get_viewport_rect().size / Vector2(1920, 1080)
	camera.make_current()
	get_viewport().size_changed.connect(func(): camera.zoom = get_viewport_rect().size / Vector2(1920,1080))
	for side in range(2):
		var left := float(side) * 960.0
		var mask_bits := 8 if side == 0 else 16
		_label("ORIGINAL LIGHTING" if side == 0 else "NORMAL MAPS ON", Vector2(left + 55, 160), Vector2(850, 55), 36)
		if side == 1:
			right_title = get_child(get_child_count() - 1) as Label
		for index in range(3):
			var subject := _subject(index, side == 1, mask_bits)
			subject.position = Vector2(left + 180.0 + index * 300.0, 490)
			subject.scale = Vector2.ONE * 1.65
			add_child(subject)
			subjects.append(subject)
			_label(["Player ship", "Gunboat", "Barrel"][index], Vector2(left + 70 + index * 300, 695), Vector2(240, 40), 27)
		var sweep := PointLight2D.new()
		sweep.texture = VisualFX.glow_texture
		sweep.texture_scale = 1100.0 / 128.0
		sweep.height = 160.0
		sweep.color = Color(1.0, 0.80, 0.50)
		sweep.energy = 0.65
		sweep.range_item_cull_mask = mask_bits
		sweep.shadow_enabled = false
		sweep.enabled = false
		add_child(sweep)
		sweep_lights.append(sweep)
	_label("NORMAL MAP TRIAL", Vector2(180, 42), Vector2(1560,70), 44)
	_label("Same art and light settings on both sides. Subjects shown at 1.65 times gameplay size.", Vector2(100,785), Vector2(1720,45),24)
	_label("Warm explosion flashes repeat. Try a moving light to inspect the surface shape.", Vector2(100,830), Vector2(1720,45),24)
	var controls := HBoxContainer.new()
	controls.position = Vector2(245,930)
	controls.add_theme_constant_override("separation", 20)
	controls.theme = preload("res://themes/nautical.tres")
	add_child(controls)
	_button(controls, "Flash  SPACE", flash)
	sweep_button = _button(controls, "Moving light  L", toggle_sweep)
	normal_button = _button(controls, "Normals ON  F7", toggle_normals)
	_button(controls, "Return  ESC", leave)
	VisualFX.settings_changed.connect(_settings_changed)
	_settings_changed()

func _subject(kind: int, normals: bool, mask_bits: int) -> Node2D:
	var source: Node2D = [PLAYER, ENEMY, BARREL][kind].instantiate()
	var holder := Node2D.new()
	var names: Array = [["shipbase", "cannon", "stellarist"], ["enemyship", "cannon"], ["barrel"]][kind]
	for part in names:
		var art := source.get_node(NodePath(part)) as Node2D
		art.owner = null
		for child in art.get_children():
			art.remove_child(child)
			child.free()
		art.set_script(null)
		source.remove_child(art)
		holder.add_child(art)
		art.show()
		art.light_mask = mask_bits
		VisualFX.register_weather_sprite(art)
		if part != "stellarist":
			# Attach after entering the tree, using the same binding as gameplay.
			art.ready.connect(VisualFX.register_normal_trial.bind(art, normals), CONNECT_ONE_SHOT)
		if art is AnimatedSprite2D:
			art.play("idle")
			pose_sprites.append(art)
		if kind == 1 and part == "enemyship":
			art.position.x = -5.0
			art.scale = Vector2(0.6,0.6)
	if kind == 1:
		holder.rotation = PI
	source.free()
	return holder

func _label(value: String, at: Vector2, extent: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.position = at
	label.size = extent
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.10,0.20,0.28))
	label.add_theme_color_override("font_outline_color", Color(0.89,0.99,1.0,0.9))
	label.add_theme_constant_override("outline_size", 5)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func _button(parent: Node, value: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(340,65)
	button.add_theme_font_size_override("font_size", 24)
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _settings_changed() -> void:
	var on: bool = VisualFX.enabled and VisualFX.normal_maps_enabled
	if right_title != null:
		right_title.text = "NORMAL MAPS ON" if on else "NORMAL MAPS OFF"
	if normal_button != null:
		normal_button.text = "Normals ON  F7" if on else "Normals OFF  F7"
	for light in sweep_lights:
		light.enabled = moving_light and VisualFX.enabled

func toggle_normals() -> void:
	VisualFX.normal_maps_enabled = not VisualFX.normal_maps_enabled
	VisualFX.settings_changed.emit()

func toggle_sweep() -> void:
	moving_light = not moving_light
	sweep_button.text = "Moving light ON  L" if moving_light else "Moving light OFF  L"
	_settings_changed()
	next_flash = 3.0

func _process(delta: float) -> void:
	elapsed += delta
	var pose: String = ["idle", "left", "idle", "right"][int(elapsed / 2.0) % 4]
	for sprite in pose_sprites:
		if sprite.sprite_frames.has_animation(pose):
			sprite.play(pose)
	for side in range(sweep_lights.size()):
		sweep_lights[side].position = Vector2(side * 960.0 + 480.0 + sin(elapsed * 0.7) * 320.0, 410.0 + cos(elapsed * 0.7) * 100.0)
	if not moving_light:
		next_flash -= delta
		if next_flash <= 0.0:
			flash()

func flash() -> void:
	next_flash = 3.5
	if not VisualFX.enabled:
		return
	# One identical light per subject. Masks prevent the two sides lighting each other.
	for index in range(subjects.size()):
		var subject := subjects[index]
		var origin := subject.position + Vector2(-60, -110)
		var pulse := PULSE.new()
		pulse.position = origin
		pulse.radius = 360.0
		pulse.duration = 0.24
		pulse.light_energy = VisualFX.event_light_energy
		pulse.opacity = 0.56
		pulse.tint = Color(1.0,0.62,0.22)
		pulse.glow_texture = VisualFX.glow_texture
		pulse.light_mask_bits = 8 if index < 3 else 16
		pulse.add_to_group("rw_transient_fx")
		add_child(pulse)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.physical_keycode == KEY_SPACE:
		flash()
	elif event.physical_keycode == KEY_L:
		toggle_sweep()
	elif event.physical_keycode == KEY_ESCAPE:
		leave()
	else:
		return
	get_viewport().set_input_as_handled()

func leave() -> void:
	if exiting or Transition.busy:
		return
	exiting = true
	Transition.load_scene("res://scenes/main_menu.tscn")
