extends PanelContainer

var lifetime: Tween
var elapsed: float = 0.0
var dismissing: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.0
	lifetime = create_tween()
	lifetime.tween_property(self, "modulate:a", 1.0, 0.15)
	lifetime.tween_interval(3.5)
	lifetime.tween_property(self, "modulate:a", 0.0, 0.55)
	lifetime.tween_callback(queue_free)

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed > 1.0 and not dismissing:
		if Input.is_action_pressed("Left") or Input.is_action_pressed("Right") or Input.is_action_pressed("Up") or Input.is_action_pressed("Down"):
			dismiss()

func dismiss() -> void:
	if dismissing:
		return
	dismissing = true
	if lifetime and lifetime.is_valid():
		lifetime.kill()
	lifetime = create_tween()
	lifetime.tween_property(self, "modulate:a", 0.0, 0.30)
	lifetime.tween_callback(queue_free)
