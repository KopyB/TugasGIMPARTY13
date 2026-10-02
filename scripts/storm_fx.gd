extends CanvasLayer
## Weather persists through the menu departure. It never changes hitboxes or UI.

var intensity := 0.0
var clock := 0.0
var lightning := 0.0
var next_lightning := 14.0
var surface: Control
var weather_tween: Tween
var weather_rng := RandomNumberGenerator.new()
var departure_flash: ColorRect
var flash_layer: CanvasLayer
var flash_tween: Tween

func _ready() -> void:
	process_priority = -100
	layer = 2
	weather_rng.randomize()
	surface = preload("res://scripts/storm_rain.gd").new()
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(surface)
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash_layer = CanvasLayer.new()
	flash_layer.layer = 250
	add_child(flash_layer)
	departure_flash = ColorRect.new()
	departure_flash.name = "HardModeFlash"
	departure_flash.color = Color(0.94, 0.98, 1.0, 0.0)
	departure_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_layer.add_child(departure_flash)
	departure_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	VisualFX.settings_changed.connect(_refresh)
	_refresh()

func _clear_departure_flash() -> void:
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
	if departure_flash != null:
		departure_flash.color.a = 0.0

func reset_menu() -> void:
	_clear_departure_flash()
	if weather_tween and weather_tween.is_valid():
		weather_tween.kill()
	intensity = 0.0
	lightning = 0.0
	clock = 0.0
	next_lightning = weather_rng.randf_range(8.0, 12.0)
	_refresh()

func begin_departure(hard: bool) -> void:
	if weather_tween and weather_tween.is_valid():
		weather_tween.kill()
	_clear_departure_flash()
	lightning = 0.0
	weather_tween = create_tween()
	if hard:
		# White out immediately, build the storm while covered, then reveal it.
		departure_flash.color.a = 1.0
		weather_tween.tween_property(self, "intensity", 1.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		flash_tween = create_tween()
		flash_tween.tween_interval(0.08)
		flash_tween.tween_property(departure_flash, "color:a", 0.0, 0.62).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		weather_tween.tween_property(self, "intensity", 0.0, 0.35)
	_refresh()

func enter_game(hard: bool) -> void:
	intensity = 1.0 if hard else 0.0
	_refresh()

func _process(delta: float) -> void:
	clock += delta
	lightning = maxf(0.0, lightning - delta * 3.0)
	if intensity > 0.9:
		next_lightning -= delta
		if next_lightning <= 0.0:
			_strike(weather_rng.randf_range(0.60, 0.85))
			next_lightning = weather_rng.randf_range(10.0, 17.0)
	_refresh()

func _refresh() -> void:
	if flash_layer != null:
		flash_layer.visible = VisualFX.enabled and departure_flash.color.a > 0.001
	RenderingServer.global_shader_parameter_set("rw_weather_time", clock)
	RenderingServer.global_shader_parameter_set("rw_weather_strength", intensity if VisualFX.enabled else 0.0)
	if surface == null:
		return
	surface.visible = VisualFX.enabled and (intensity > 0.001 or lightning > 0.001)
	surface.set("weather_time", clock)
	surface.set("strength", intensity)
	surface.set("lightning", lightning)
	surface.queue_redraw()

func _strike(amount: float) -> void:
	lightning = amount
	surface.set("bolt_x", weather_rng.randf_range(1220.0, 1770.0))
	var scene := get_tree().current_scene
	if scene != null:
		var departing_ship := scene.get_node_or_null("animationstella") as Node2D
		if departing_ship != null and departing_ship.visible:
			VisualFX.lightning(departing_ship.global_position)
