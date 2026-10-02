extends Node

var camera: Camera2D
var overlay: ColorRect
var is_screenshake_enabled: bool = true
var impulse: float = 0.0
var impulse_duration: float = 0.2
var impulse_left: float = 0.0
var continuous_amount: float = 0.0
var continuous_speed: float = 0.08
var elapsed: float = 0.0
var overlay_tween: Tween
var zoom_tween: Tween

func register_camera(cam: Camera2D) -> void:
	camera = cam
	impulse = 0.0
	impulse_left = 0.0
	continuous_amount = 0.0
	_apply_camera_shake(Vector2.ZERO, 0.0)

func shake(intensity: float, duration: float) -> void:
	if not is_instance_valid(camera) or not is_screenshake_enabled:
		return
	# One shared impulse avoids competing tweens and accumulated camera offsets.
	impulse = maxf(impulse, minf(intensity * 0.65, 7.5))
	impulse_duration = maxf(duration, 0.12)
	impulse_left = impulse_duration

func start_loop_shake(intensity: float, speed: float) -> void:
	if not is_screenshake_enabled:
		return
	continuous_amount = minf(intensity * 0.16, 1.8)
	continuous_speed = maxf(speed, 0.04)

func stop_loop_shake() -> void:
	continuous_amount = 0.0
	if is_instance_valid(camera) and impulse_left <= 0.0:
		_apply_camera_shake(Vector2.ZERO, 0.0)

func _process(delta: float) -> void:
	if not is_instance_valid(camera) or not camera.is_inside_tree():
		return
	elapsed += delta
	impulse_left = maxf(impulse_left - delta, 0.0)
	if not is_screenshake_enabled:
		impulse = 0.0
		impulse_left = 0.0
		continuous_amount = 0.0
		_apply_camera_shake(Vector2.ZERO, 0.0)
		return
	var envelope := pow(impulse_left / impulse_duration, 1.5)
	var kick := Vector2(sin(elapsed * 91.0), sin(elapsed * 113.0 + 0.7)) * impulse * envelope
	var phase := elapsed / continuous_speed
	var hum := Vector2(sin(phase * 2.1), sin(phase * 2.7 + 0.5)) * continuous_amount
	var requested := (kick + hum).limit_length(7.5)
	_apply_camera_shake(requested, minf(7.5, impulse * envelope + continuous_amount))
	if impulse_left <= 0.0:
		impulse = 0.0

func _apply_camera_shake(requested: Vector2, strength: float) -> void:
	if not is_instance_valid(camera) or not camera.is_inside_tree():
		return
	if camera.has_method("apply_shake"):
		camera.call("apply_shake", requested, strength)
	else:
		camera.offset = requested

func zoom(target_zoom: Vector2, duration: float = 0.5) -> void:
	if not is_instance_valid(camera):
		return
	if zoom_tween and zoom_tween.is_valid():
		zoom_tween.kill()
	var original := camera.zoom
	zoom_tween = camera.create_tween()
	zoom_tween.tween_property(camera, "zoom", target_zoom, duration * 0.5).set_trans(Tween.TRANS_SINE)
	zoom_tween.tween_property(camera, "zoom", original, duration * 0.5).set_trans(Tween.TRANS_SINE)

func register_overlay(node: ColorRect) -> void:
	overlay = node

func flash_darken(amount: float = 0.5, total_duration: float = 0.4) -> void:
	if not is_instance_valid(overlay):
		return
	if overlay_tween and overlay_tween.is_valid():
		overlay_tween.kill()
	overlay_tween = overlay.create_tween()
	overlay_tween.tween_property(overlay, "color:a", amount, total_duration * 0.3).set_trans(Tween.TRANS_SINE)
	overlay_tween.tween_interval(total_duration * 0.2)
	overlay_tween.tween_property(overlay, "color:a", 0.0, total_duration * 0.5).set_trans(Tween.TRANS_SINE)
