extends RefCounted
## Shared current and bounded, time-based encounter pacing. No score feedback loop.

static func current_speed(hard: bool) -> float:
	return 215.0 if hard else 185.0

static func gunboat_speed(hard: bool) -> float:
	return current_speed(hard) + (125.0 if hard else 90.0)

static func spawn_interval(seconds: float, phase_seconds: float, hard: bool) -> float:
	var ramp_seconds := 210.0 if hard else 300.0
	var progress := clampf(seconds / ramp_seconds, 0.0, 1.0)
	# Ease out brings pressure forward, while preserving a finite late-game cap.
	progress = 1.0 - pow(1.0 - progress, 1.35)
	var trough := lerpf(2.5 if hard else 3.6, 1.0 if hard else 1.5, progress)
	var peak := lerpf(1.45 if hard else 2.2, 0.38 if hard else 0.65, progress)
	var period := 24.0 if hard else 32.0
	var pressure := (1.0 - cos(phase_seconds * TAU / period)) * 0.5
	return lerpf(trough, peak, pressure)

static func first_spawn_delay(hard: bool) -> float:
	return 0.65 if hard else 1.0

static func recovery_delay(hard: bool) -> float:
	return 1.5 if hard else 2.0
