extends AudioStreamPlayer

@export var fade_duration := 0.75
@export var start_volume_db := -30.0

var has_faded_in := false
var active_tween: Tween 
var target_volume_db := 0.0 

func _ready():
	if stream:
		stream.loop = true

	if not has_faded_in:
		volume_db = start_volume_db
	else:
		volume_db = target_volume_db 

	play()

	if not has_faded_in:
		start_fade_in()
		has_faded_in = true

# Fungsi Fade In Internal
func start_fade_in():
	if active_tween: active_tween.kill()
	
	active_tween = create_tween()
	active_tween.tween_property(self, "volume_db", target_volume_db, fade_duration).set_trans(Tween.TRANS_SINE)

func set_target_volume(new_db: float):
	target_volume_db = new_db
	

	if active_tween and active_tween.is_valid():
		active_tween.kill()
		active_tween = create_tween()
		active_tween.tween_property(self, "volume_db", target_volume_db, fade_duration).set_trans(Tween.TRANS_SINE)
	else:
		volume_db = target_volume_db
