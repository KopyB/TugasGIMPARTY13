extends Node

var camera: Camera2D
var loop_tween: Tween

func register_camera(cam: Camera2D):
	camera = cam

func shake(intensity, duration): #shake pendek
	if not camera:
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

func start_loop_shake(intensity := 6.0, speed := 0.1): #shake panjang (buat laser sm siren)
	if not camera:
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
