extends CanvasLayer
## Available in menus, during play, and while paused.

const BUILD_ID := "RW VISUAL R11 · 2026-09-30"
var panel: PanelContainer
var normal_status: Label
var status_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 200
	panel = PanelContainer.new()
	panel.position = Vector2(24, 100)
	panel.theme = preload("res://themes/nautical.tres")
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margin)
	var label := Label.new()
	label.text = BUILD_ID + "\nFull screen Hard flash and enemy collisions\nF7 toggles normals\nF10 opens comparison from the main menu\nF9 hides this panel"
	label.add_theme_font_size_override("font_size", 24)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(label)
	panel.hide()
	normal_status = Label.new()
	normal_status.position = Vector2(24, 28)
	normal_status.add_theme_font_size_override("font_size", 24)
	normal_status.add_theme_color_override("font_color", Color.WHITE)
	normal_status.add_theme_color_override("font_outline_color", Color(0.05, 0.14, 0.20))
	normal_status.add_theme_constant_override("outline_size", 8)
	normal_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(normal_status)
	normal_status.hide()
	print(BUILD_ID)

func show_normal_status(active: bool) -> void:
	if status_tween and status_tween.is_valid():
		status_tween.kill()
	normal_status.text = "Normal maps ON" if active else "Normal maps OFF"
	normal_status.modulate.a = 1.0
	normal_status.show()
	status_tween = create_tween()
	status_tween.tween_interval(1.5)
	status_tween.tween_property(normal_status, "modulate:a", 0.0, 0.3)
	status_tween.tween_callback(normal_status.hide)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F9:
			panel.visible = not panel.visible
			get_viewport().set_input_as_handled()
