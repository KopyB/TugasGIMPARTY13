extends Node

var camera: Camera2D
var loop_tween: Tween
var is_screenshake_enabled: bool = true

func register_camera(cam: Camera2D):
	camera = cam

func shake(intensity, duration): #shake pendek
	if not camera or not is_screenshake_enabled:
		return

	var tween = camera.create_tween()
	var orig_offset = camera.offset

	tween.tween_property(
		camera, "offset",
		orig_offset + Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity)),
		duration * 0.25
	)

	tween.tween_property(
		camera, "offset",
		orig_offset + Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity)),
		duration * 0.25
	)

	tween.tween_property(
		camera, "offset",
		orig_offset,
		duration * 0.5
	)

func start_loop_shake(intensity, speed): #shake panjang (buat laser sm siren)
	if not camera or not is_screenshake_enabled:
		return

	stop_loop_shake()

	loop_tween = camera.create_tween().set_loops()  # infinite loop
	var orig_offset = camera.offset

	# This repeats forever
	loop_tween.tween_property(
		camera, "offset",
		orig_offset + Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity)),
		speed
	)
	loop_tween.tween_property(
		camera, "offset",
		orig_offset + Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity)),
		speed
	)

func stop_loop_shake():
	if loop_tween:
		loop_tween.kill()
	if camera:
		camera.offset = Vector2.ZERO

func zoom(target_zoom: Vector2, duration := 0.5):
	if not camera:
		return

	var half := duration * 0.5
	var orig_zoom := camera.zoom
	var tween := camera.create_tween()

	# Zoom in
	tween.tween_property(camera, "zoom", target_zoom, half).set_trans(Tween.TRANS_SINE)

	# Then zoom out
	tween.tween_property(camera, "zoom", orig_zoom, half).set_trans(Tween.TRANS_SINE)
	
var overlay: ColorRect = null

func register_overlay(node: ColorRect):
	overlay = node

func flash_darken(amount := 0.5, total_duration := 0.4):
	if not overlay:
		return

	var tween = create_tween()
	var c = overlay.color

	# Fade to darkness
	tween.tween_property(overlay, "color",
		Color(c.r, c.g, c.b, amount),
		total_duration * 0.3
	).set_trans(Tween.TRANS_SINE)

	# Hold briefly
	tween.tween_interval(total_duration * 0.2)

	# Fade back to clear
	tween.tween_property(overlay, "color",
		Color(c.r, c.g, c.b, 0.0),
		total_duration * 0.5
	).set_trans(Tween.TRANS_SINE)
