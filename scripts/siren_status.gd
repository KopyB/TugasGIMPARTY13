extends PanelContainer
## Same icon and timer layout as the other powers, driven by real player state.
var actor
var bar: ProgressBar
var countdown: Label
var maximum := 4.0

func _ready() -> void:
	custom_minimum_size = Vector2(76, 0)
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_text = "Confusion\nControls reversed"
	var icon := preload("res://scenes/iconpowerup.tscn").instantiate()
	add_child(icon)
	bar = icon.get_node("ProgressBar") as ProgressBar
	bar.get_node("Timer").stop()
	bar.max_value = maximum
	icon.get_node("TextureRect").texture = preload("res://assets/art/powerup icon/Debuff icon.png")
	countdown = Label.new()
	countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	countdown.add_theme_font_override("font", preload("res://assets/norwester.otf"))
	countdown.add_theme_font_size_override("font_size", 22)
	countdown.add_theme_color_override("font_outline_color", Color(0.06, 0.10, 0.16))
	countdown.add_theme_constant_override("outline_size", 4)
	countdown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.add_child(countdown)
	hide()

func _process(_delta: float) -> void:
	if not is_instance_valid(actor):
		actor = get_tree().get_first_node_in_group("player")
	visible = is_instance_valid(actor) and actor.is_dizzy and not actor.is_dead
	if visible:
		maximum = maxf(maximum, actor.dizzy_timer)
		bar.max_value = maximum
		bar.value = maxf(actor.dizzy_timer, 0.0)
		countdown.text = "%.1f s" % maxf(actor.dizzy_timer, 0.0)
