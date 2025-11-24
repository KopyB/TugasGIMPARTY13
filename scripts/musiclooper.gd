extends AudioStreamPlayer

@export var fade_duration := 0.6
@export var start_volume_db := -30.0
var has_faded_in := false

func _ready():
	# Make sure stream loops
	if stream:
		stream.loop = true

	# Always start at low volume BEFORE playing audio
	if not has_faded_in:
		volume_db = start_volume_db
	else:
		volume_db = 0.0  # normal volume for future loops

	# Now start the audio
	play()

	# Fade only the first time
	if not has_faded_in:
		fade_in_once()
		has_faded_in = true


func fade_in_once():
	var tween = create_tween()
	tween.tween_property(self, "volume_db", 0.0, fade_duration).set_trans(Tween.TRANS_SINE)
