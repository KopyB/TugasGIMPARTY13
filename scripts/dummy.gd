extends Area2D

const PACING = preload("res://scripts/voyage_pacing.gd")

signal enemy_died

const ARENA = preload("res://scripts/arena_geometry.gd")
var has_entered_arena := false

var enemyship: Sprite2D = null
var collision_shape_2d: CollisionShape2D = null
var cannon: Sprite2D = null
var is_game_over = false
var is_dead := false

# TIPE MUSUH
enum Type {GUNBOAT, BOMBER, RBOMBER, PARROT, TORPEDO_SHARK, SIREN, RSIREN}
@export var enemy_type = Type.GUNBOAT
@onready var pathfollow := get_parent() as PathFollow2D
@onready var dummy_root = get_parent().get_parent()
@onready var shadow_path = dummy_root.get_node_or_null("shadowpath/parrotshadowpath")



# STATISTIK MUSUH NORMAL
var speed = 275.0
var health = 2
var shoot_timer = 0.0
var shoot_interval = 2.0 # Default Gunboat (2 detik)

var is_paralyzed = false

# --- SHARK VARIABLE ---
var shark_timer = 0.0
var shark_lock_duration = randf_range(3.8, 4.8) # Locks on randomly
var is_shark_charging = false
var shark_charge_direction = Vector2.ZERO
var shark_charge_speed = randf_range(1000.0, 1300.0)
var torpedoshark: AnimatedSprite2D = null
var shark_dash_count = 0 # Completed charge starts, at most two.
var shark_retry_decided := false
var shark_warning_left := 0.0
const SHARK_TURN_MARGIN := 130.0
var charge_warning_active := false

# --- SIREN VARIABLE ---
var is_diving = false
var is_screaming = false
var siren: AnimatedSprite2D = null

# LOAD ASSET 
var powerup_scene = preload("res://scenes/power_up.tscn")
var bullet_scene = preload("res://scenes/bulletenemy.tscn")
var barrel_scene = preload("res://scenes/barrelbomb.tscn")
var explosion_scene = preload("res://scenes/explosion.tscn")
var bomber_barrel = preload("res://assets/art/BomberWithBarrel.png")
var bomber_noBarrel = preload("res://assets/art/BomberNoBarrel.png")
var gun_boat = preload("res://assets/art/pirate gunboat base.png")
var floating_text_scene = preload("res://scenes/FloatingText.tscn")

@onready var taunt: AudioStreamPlayer2D = get_node_or_null("parrot_taunt")
@onready var pdeath: AudioStreamPlayer2D = get_node_or_null("parrot_hurt")
@onready var skrem : AudioStreamPlayer2D = get_node_or_null("siren/scream")
@onready var cannonsfx: AudioStreamPlayer2D = get_node_or_null("cannon/cannonsfx")
@onready var trails: AnimatedSprite2D = get_node_or_null("trails")
@onready var parrot_whistle: AudioStreamPlayer2D = get_node_or_null("parrot_whistle")

var player = null 

func _ready():
	if enemy_type != Type.PARROT:
		set_collision_mask_value(1, true)
	VisualFX.register_actor(self, enemy_type in [Type.GUNBOAT, Type.BOMBER, Type.RBOMBER])
	add_to_group("enemies") 
	player = get_tree().get_first_node_in_group("player")
	
	if has_node("enemyship"):
		enemyship = $enemyship
		
	if has_node("CollisionShape2D"):
		collision_shape_2d = $CollisionShape2D
		
	if has_node("cannon"):
		cannon = $cannon
		
	if has_node("torpedoshark"):
		torpedoshark = $torpedoshark
		torpedoshark.hide() # Aman, karena sudah dicek ada atau tidak
		$trails.hide()
		
	if has_node("parrot_taunt"):
		taunt = get_node_or_null("parrot_taunt")
		
	if has_node("parrot_hurt"):
		pdeath = get_node_or_null("parrot_hurt")
	
	if has_node("siren"):
		siren = $siren
		siren.hide()
		
	# Setup awal berdasarkan tipe
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
		
	if collision_shape_2d and collision_shape_2d.shape:
		collision_shape_2d.shape = collision_shape_2d.shape.duplicate()
	
	if collision_shape_2d:
		collision_shape_2d.disabled = false
	
	# TIPE 0: GUNBOAT
	if enemy_type == Type.GUNBOAT:
		if enemyship:
			enemyship.texture = gun_boat
			enemyship.position.x = -5.0
			enemyship.scale = Vector2(0.6, 0.6)
			$trails.show()
			$trails.position = Vector2(1.0, 21.0)
			$trails.scale = Vector2(0.3,0.3)
			$trails.play("trailvert_up")
			
		if cannon:
			cannon.show()
		
		# Set Hitbox Gunboat 
		if collision_shape_2d and collision_shape_2d.shape is RectangleShape2D:
			collision_shape_2d.shape.size = Vector2(284.0, 116.0)
		
		shoot_interval = randf_range(1.7, 2.25)
		rotation_degrees = 180 # Hadap Bawah
		
	# TIPE 1: BOMBER 
	elif enemy_type == Type.BOMBER:
		if cannon: cannon.hide()
		
		if enemyship:
			enemyship.rotation = -PI/2
			enemyship.scale = Vector2(0.15, 0.15)
			$trails.show()
			$trails.position = Vector2(9.0, -16.0)
			$trails.rotation = PI/2
			$trails.scale = Vector2(0.33,0.33)
			$trails.play("trailhorz_left")
		
		# Set Hitbox Bomber (Lebih Besar)
		if collision_shape_2d and collision_shape_2d.shape is RectangleShape2D:
			collision_shape_2d.shape.size = Vector2(280.0, 145.0) 

		shoot_interval = randf_range(0.8, 1.0) 
		speed = randf_range(245, 300)
		rotation_degrees = 90 # Hadap Kanan
		
	# TIPE 2: RBOMBER (Bomber dari Kanan)
	elif enemy_type == Type.RBOMBER:
		if cannon: cannon.hide()
		
		if enemyship:
			enemyship.texture = bomber_barrel
			enemyship.rotation = -PI/2 
			enemyship.scale = Vector2(0.15, -0.15) 
			$trails.show()
			$trails.position = Vector2(-9.0, -16.0)
			$trails.rotation = PI/2
			$trails.scale = Vector2(0.33,0.33)
			$trails.play("trailhorz_left")
			
		# Set Hitbox RBomber (Sama kayak Bomber)
		if collision_shape_2d and collision_shape_2d.shape is RectangleShape2D:
			collision_shape_2d.shape.size = Vector2(280.0, 145.0)
			
		shoot_interval = randf_range(0.8, 1.0) 
		speed = randf_range(245, 300) 
		rotation_degrees = -90 

	# TIPE 3: PARROT 
	elif enemy_type == Type.PARROT:
		health = 1
		add_to_group("parrots")
		print("Parrot spawned")

	# TIPE 4: TORPEDO SHARK 
	elif enemy_type == Type.TORPEDO_SHARK:
		health = 2
		speed = 65 # Speed awal (aiming phase)
		# Hitbox Shark 
		if collision_shape_2d and collision_shape_2d.shape is RectangleShape2D:
			collision_shape_2d.shape.size = Vector2(100.0, 50.0)
		if cannon:
			cannon.hide()
		if enemyship:
			enemyship.hide()
		if torpedoshark:
			torpedoshark.show()

	# TIPE 5: SIREN 
	elif enemy_type == Type.SIREN:
		if cannon: cannon.hide()
		if enemyship:
			enemyship.hide()
		if siren:
			siren.show()
			siren.play("swim")
			siren.flip_h = false
			
		rotation_degrees = 0
		speed = randi_range(140, 160)
	
	# TIPE 6: RSIREN 
	elif enemy_type == Type.RSIREN:
		if cannon: cannon.hide()
		if enemyship:
			enemyship.hide()
		if siren:
			siren.show()
			siren.play("swim")
			siren.flip_h = true
			
		rotation_degrees = 0
		speed = randi_range(140, 160)
	
	var cues := preload("res://scripts/encounter_cues.gd").new()
	cues.name = "EncounterCues"
	add_child(cues)
	if enemy_type == Type.TORPEDO_SHARK:
		VisualFX.add_silhouette(self, torpedoshark)
	if GameData.is_hard_mode:
		apply_hard_mode_stats()
	if enemy_type == Type.GUNBOAT:
		speed = PACING.gunboat_speed(GameData.is_hard_mode)
		shoot_timer = randf_range(0.1, 0.45) * shoot_interval

func apply_hard_mode_stats():
	var hp_multiplier = 1.5     # Multiply?: 1.5 (darah alot)
	var speed_multiplier = 1.5  # Multiply?: 1.5 (lebih cepat)
	var shoot_multiplier = 1.1  # Multiply?: 1.1 (fire rate lebih cepat)
	var shark_detection_reducer = 1.5 # Reduce?: 1.5 (faster shark lock duration)
	
	health = int(health * hp_multiplier)
	
	if enemy_type != Type.TORPEDO_SHARK:
		speed = speed * speed_multiplier
	else:
		shark_charge_speed = shark_charge_speed * speed_multiplier
		shark_lock_duration = shark_lock_duration - shark_detection_reducer

	shoot_interval = shoot_interval / shoot_multiplier

func cease_fire():
	is_game_over = true
	shoot_timer = 0
	
	if enemy_type == Type.TORPEDO_SHARK:
		is_shark_charging = false
		shark_charge_speed = 0	
		
func _process(delta):
	if is_game_over or is_dead:
		return
		
	if is_paralyzed:
		if trails and is_instance_valid(trails):
			trails.hide()
		if enemy_type == Type.GUNBOAT:
			position.y += PACING.current_speed(GameData.is_hard_mode) * delta
		elif enemy_type == Type.BOMBER or enemy_type == Type.RBOMBER or enemy_type == Type.SIREN or enemy_type == Type.RSIREN or enemy_type == Type.TORPEDO_SHARK:
			position.y += speed * delta
		return
	
		
	if enemy_type == Type.GUNBOAT:
		position.y += speed * delta
		
	elif enemy_type == Type.BOMBER:
		position.x += speed * delta
		if shoot_timer >= shoot_interval/2:
			enemyship.texture = bomber_barrel
		else:
			enemyship.texture = bomber_noBarrel
	
	elif enemy_type == Type.RBOMBER:
		position.x -= speed * delta
		if shoot_timer >= shoot_interval/2:
			enemyship.texture = bomber_barrel
		else:
			enemyship.texture = bomber_noBarrel
	
	elif enemy_type == Type.TORPEDO_SHARK:
		handle_shark_behavior(delta)

	elif enemy_type == Type.SIREN:
		if not is_screaming:
			position.x += speed * delta
		else:
			position.y += PACING.current_speed(GameData.is_hard_mode) * delta
		
	elif enemy_type == Type.RSIREN:
		if not is_screaming:
			position.x -= speed * delta
		else:
			position.y += PACING.current_speed(GameData.is_hard_mode) * delta
	
	if enemy_type != Type.TORPEDO_SHARK and enemy_type != Type.SIREN and enemy_type != Type.RSIREN:
		shoot_timer += delta
		if shoot_timer >= shoot_interval:
			shoot_timer = 0
			perform_attack()
			
	check_despawn()

# --- FUNGSI DESPAWN ---
func check_despawn():
	if enemy_type == Type.PARROT:
		return # Its authored flight path owns its lifetime.
	var bounds: Rect2 = ARENA.visual_bounds(self)
	if ARENA.RECT.intersects(bounds):
		has_entered_arena = true
	elif has_entered_arena:
		queue_free() # The entire artwork and wake have left, not only the origin.

# --- FUNGSI PARALYZED ---
func set_paralyzed(status):
	is_paralyzed = status
	if enemy_type == Type.PARROT:
		pathfollow.is_paralyzed = status
		shadow_path.is_paralyzed = status
	if is_paralyzed:
		modulate = Color(0.5, 0.5, 0.5, 1) 
		if enemy_type == Type.TORPEDO_SHARK and torpedoshark:
			torpedoshark.pause()
		elif (enemy_type == Type.SIREN or enemy_type == Type.RSIREN) and siren:
			siren.pause()
	else:
		modulate = Color.WHITE
		# Resume Animasi Hiu
		if enemy_type == Type.TORPEDO_SHARK and torpedoshark:
			torpedoshark.play() # Lanjut mainkan animasi terakhir
			
		# Resume Animasi Siren
		elif (enemy_type == Type.SIREN or enemy_type == Type.RSIREN) and siren:
			siren.play() 
	
	if status == false and enemy_type == Type.BOMBER or enemy_type == Type.RBOMBER or enemy_type == Type.GUNBOAT:
			$trails.show()
			 
# --- FUNGSI SERANGAN ---
func perform_attack():
	if enemy_type == Type.GUNBOAT:
		fire_gunboat()
	elif enemy_type == Type.BOMBER or enemy_type == Type.RBOMBER:
		drop_barrel()
		

func fire_gunboat():
	# Queued entry rows cannot fire into the arena before the ship is visible.
	if not ARENA.RECT.has_point(global_position) or global_position.y < 60.0:
		return
	if is_instance_valid(player):
		
		# Jika Y Musuh > Y Player, artinya Musuh ada DI BAWAH (di belakang) Player.
		# Beri toleransi sedikit (50 pixel)
		if global_position.y >= player.global_position.y - 50:
			return 
		VisualFX.recoil(cannon)
		spawn_enemy_bullet(0)
		
		if GameData.is_hard_mode:   
			if randf() <= 0.40:
				spawn_enemy_bullet(-15)  
				spawn_enemy_bullet(15)   
		
		cannonsfx.play()
		

func spawn_enemy_bullet(angle_offset):
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.source_actor_id = get_instance_id()
	
	bullet.look_at(player.global_position)
	bullet.rotation_degrees += angle_offset
	bullet.direction = Vector2.RIGHT.rotated(bullet.rotation)
	
	get_tree().current_scene.add_child(bullet)
			
func drop_barrel():
	if not ARENA.RECT.has_point(global_position):
		return
	var barrel = barrel_scene.instantiate()
	barrel.global_position = global_position
	
	if GameData.is_hard_mode:
		if randf() <= 0.40:
			barrel.enable_fast_mode()
			
	get_tree().current_scene.call_deferred("add_child", barrel)
	$splashsfx.play()
	# Opsional: Ubah sprite musuh jadi "kosong" sebentar (Visual Direction)
	# $Sprite2D.texture = load("res://assets/bomber_empty.png")

# --- KAMIKAZE ---
func _on_body_entered(body):
	if is_dead:
		return
	if body.has_method("take_damage_player"):
		body.take_damage_player()
		die() 
		
# --- FUNGSI KHUSUS BEHAVIOUR SHARK ---
func handle_shark_behavior(delta: float) -> void:
	if charge_warning_active:
		# The warning locks direction, but must not reuse the last charge's velocity.
		shark_warning_left -= delta
		if shark_warning_left <= 0.0:
			start_shark_charge()
		return
	if not is_shark_charging:
		shark_timer += delta
		if is_instance_valid(player):
			look_at(player.global_position)
		# The first approach swims in. The second lock-on holds its visible turn point.
		if shark_dash_count == 0:
			position += Vector2.RIGHT.rotated(rotation) * speed * delta
		torpedoshark.play("scout")
		if shark_timer >= shark_lock_duration:
			show_charge_indicator()
			shark_charge_direction = Vector2.ZERO
			torpedoshark.play("transition")
			shark_warning_left = _shark_transition_duration()
		return

	var next_position: Vector2 = global_position + shark_charge_direction * shark_charge_speed * delta
	# Predict the edge crossing before moving, using world bounds at every window size.
	var turn_bounds := ARENA.RECT.grow(-SHARK_TURN_MARGIN)
	var leaving: bool = (shark_charge_direction.x > 0.0 and next_position.x >= turn_bounds.end.x) \
		or (shark_charge_direction.x < 0.0 and next_position.x <= turn_bounds.position.x) \
		or (shark_charge_direction.y > 0.0 and next_position.y >= turn_bounds.end.y) \
		or (shark_charge_direction.y < 0.0 and next_position.y <= turn_bounds.position.y)
	if GameData.is_hard_mode and shark_dash_count == 1 and not shark_retry_decided and leaving:
		shark_retry_decided = true
		if randf() <= 0.40:
			perform_double_dash()
			return
	global_position = next_position
	torpedoshark.play("swimming")
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			_on_body_entered(body)

func _shark_transition_duration() -> float:
	var frames := torpedoshark.sprite_frames
	var duration := 0.0
	for index in range(frames.get_frame_count("transition")):
		duration += frames.get_frame_duration("transition", index)
	return duration / maxf(frames.get_animation_speed("transition") * absf(torpedoshark.speed_scale), 0.01)

func perform_double_dash() -> void:
	if shark_dash_count != 1 or not is_shark_charging:
		return
	shark_retry_decided = true
	is_shark_charging = false
	charge_warning_active = false
	shark_charge_direction = Vector2.ZERO
	shark_timer = 0.0
	shark_lock_duration = 1.0
	torpedoshark.play("scout")

func start_shark_charge() -> void:
	if is_dead or is_game_over or shark_dash_count >= 2:
		return
	charge_warning_active = false
	is_shark_charging = true
	shark_dash_count += 1
	shark_charge_direction = Vector2.RIGHT.rotated(rotation)
	$torpedoshark/sharkcharge.play()
	torpedoshark.play("swimming")

func trigger_siren_scream():
	if is_screaming:
		return
	
	is_screaming = true
	$EncounterCues.cast()
	siren.play("shot")
	print("SIREN SCREAM! PLAYER DIZZYY!")
	skrem.play()

	if is_instance_valid(player) and player.has_method("apply_dizziness"):
		player.apply_dizziness(4.0)

	# Active-time wait also respects Admiral paralysis and pause.
	var remaining := 3.0
	while remaining > 0.0:
		await get_tree().process_frame
		if is_dead or not is_inside_tree():
			return
		if not get_tree().paused and not is_paralyzed:
			remaining -= get_process_delta_time()
	is_diving = true
	siren.play("diveback")
	await siren.animation_finished
	if not is_dead:
		queue_free()

# --- LOGIKA TERIMA DAMAGE & MATI ---
func take_damage(amount):
	if is_dead:
		return
	var parrotcheck = get_tree().get_nodes_in_group("parrots").size()
	if not enemy_type == Type.PARROT:
		if parrotcheck == 0:
			if enemy_type == Type.TORPEDO_SHARK and is_shark_charging:
				if amount < 9999:
					return
			
			if enemy_type == Type.SIREN or enemy_type == Type.RSIREN:
				if is_paralyzed:
					health -= amount
					VisualFX.hit(self)
					if health <= 0:
						die()
					return 
				if is_screaming:
					health -= amount
					VisualFX.hit(self)
					if health <= 0:
						die()
					return
				if amount < health:
					trigger_siren_scream()
					get_tree().call_group("jumpscare_manager", "play_jumpscare")
					if GameData.is_hard_mode:
						print("HARD MODE: SIREN BLINDNESS APPLIED!")
						get_tree().call_group("visual_effect_manager", "trigger_siren_blindness", 4.0)
				health -= amount
				VisualFX.hit(self)
				if health <= 0:
					die()
				return 
			health -= amount
			VisualFX.hit(self)
			if health <= 0:
				die()
		else:
			VisualFX.parrot_blocked(self)
			taunt.play()
	else:
		health -= amount
		VisualFX.hit(self)
		if health <= 0:
			die()

func die():
	if is_dead:
		return
	is_dead = true
	remove_from_group("enemies")
	if collision_shape_2d:
		collision_shape_2d.set_deferred("disabled", true)
	if enemy_type == Type.PARROT:
		remove_from_group("parrots")
		hide()
		if is_instance_valid(pathfollow):
			pathfollow.set_process(false)
		if is_instance_valid(shadow_path):
			shadow_path.hide()
			shadow_path.set_process(false)
		_play_parrot_death_sound()
	var add_points = 0
	var enemy_name = ""
	
	match enemy_type:
		Type.GUNBOAT:
			add_points = 3
			enemy_name = "Gunboat"
		Type.BOMBER, Type.RBOMBER:
			add_points = 3
			enemy_name = "Bomber"
		Type.SIREN, Type.RSIREN:   
			add_points = 4
			enemy_name = "Siren"
		Type.PARROT:
			add_points = 5
			enemy_name = "Parrot"
		Type.TORPEDO_SHARK:
			add_points = 8
			enemy_name = "Shark"
			
	if GameData.is_hard_mode:
		add_points += 10 
		enemy_name = "Buffed " + enemy_name	
			
	get_tree().call_group("ui_manager", "increase_score", add_points)
	spawn_floating_text(add_points, enemy_name)
	
	GameData.enemies_killed += 1
	GameData.save_stats()
	if GameData.enemies_killed >= 30: GameData.check_and_unlock("kill_30", "Rookie")
	if GameData.enemies_killed >= 150: GameData.check_and_unlock("kill_150", "Pro")
	if GameData.enemies_killed >= 700: GameData.check_and_unlock("kill_700", "Hunter")
	if GameData.enemies_killed >= 2000: GameData.check_and_unlock("kill_2000", "True Hunter")
	if GameData.enemies_killed >= 15000: GameData.check_and_unlock("kill_15000", "Omnipotent")
	if GameData.enemies_killed >= 80000: GameData.check_and_unlock("kill_80000", "That's enough, brochacho")
	
	if is_instance_valid(player):
		if player.is_kraken_active:
			GameData.kraken_session_kills += 1
			print("Kraken Kill: ", GameData.kraken_session_kills)
			
			if GameData.kraken_session_kills >= 10:
				GameData.check_and_unlock("death_ray", "Death Ray")
				
	if not enemy_type == Type.PARROT:
		if enemyship and is_instance_valid(enemyship):
			enemyship.hide()
			
		if collision_shape_2d and is_instance_valid(collision_shape_2d):
			collision_shape_2d.set_deferred("disabled", true)
		exploded()
		spawn_powerup_chance()
		enemy_died.emit()
		if enemy_type == Type.BOMBER or enemy_type == Type.RBOMBER:
			drop_barrel()
		queue_free()
		
	elif enemy_type == Type.PARROT:
		spawn_powerup()
		if GameData.is_hard_mode and is_instance_valid(player):
			var target_x = player.global_position.x
			await trigger_airstrike(target_x)
		dummy_root.queue_free()
	else:
		queue_free()

func _play_parrot_death_sound() -> void:
	if not is_instance_valid(pdeath) or pdeath.stream == null:
		return
	var sound := AudioStreamPlayer2D.new()
	sound.stream = pdeath.stream
	sound.bus = pdeath.bus
	sound.volume_db = pdeath.volume_db
	sound.pitch_scale = pdeath.pitch_scale
	get_tree().current_scene.add_child(sound)
	sound.global_position = global_position
	sound.finished.connect(sound.queue_free)
	sound.play()

func trigger_airstrike(target_x):
	show_warning_indicator(target_x)
	await get_tree().create_timer(0.8, false).timeout
	var count = 10
	var viewport_height = get_viewport_rect().size.y
	var start_y = -50
	var gap = (viewport_height + 100) / count 
	
	for i in range(count):
		var explosion = explosion_scene.instantiate()
		explosion.is_barrel_explosion = true 
		
		explosion.global_position = Vector2(target_x, start_y + (i * gap))
		
		get_tree().current_scene.call_deferred("add_child", explosion)
		
		await get_tree().create_timer(0.2, false).timeout
		
func show_warning_indicator(x_pos):
	var warning = ColorRect.new()
	var view_size = get_viewport_rect().size
	
	# Lebar 450 Tinggi Full Height layar
	warning.size = Vector2(450, view_size.y + 200) 
	warning.position = Vector2(x_pos - 250, -100) # Tengah
	warning.color = Color(1, 0, 0, 0) 
	
	get_tree().current_scene.add_child(warning)
	
	var tween = create_tween()
	tween.tween_property(warning, "color:a", 0.4, 0.2) 
	tween.tween_property(warning, "color:a", 0.1, 0.2)
	tween.tween_property(warning, "color:a", 0.6, 0.2) 
	tween.tween_property(warning, "color:a", 0.0, 0.2)
	
	tween.tween_callback(warning.queue_free)
	
func show_charge_indicator():
	# Cleared by the actual charge event, never by an unrelated visual tween.
	charge_warning_active = true

func takes_ground_hits() -> bool:
	return not is_dead and not is_game_over and enemy_type != Type.PARROT

func take_barrel_blast() -> bool:
	# Environmental blasts bypass the parrot's bullet guard. Flying parrots and
	# actively charging sharks are the explicit exceptions to blast damage.
	if not takes_ground_hits():
		return false
	if enemy_type == Type.TORPEDO_SHARK and is_shark_charging:
		return false
	die()
	return true

func _on_area_entered(area: Area2D) -> void:
	if not takes_ground_hits() or not is_instance_valid(area) or area == self:
		return
	if area.is_in_group("enemies") and area.has_method("takes_ground_hits"):
		_resolve_enemy_contact.call_deferred(area)
	elif area.is_in_group("obstacles"):
		if area.has_method("take_damage"):
			area.take_damage(10)
		die()

func _resolve_enemy_contact(other: Area2D) -> void:
	if not takes_ground_hits() or not is_instance_valid(other) or other.is_queued_for_deletion():
		return
	if not other.takes_ground_hits():
		return
	# Same lethal ram rule as obstacles. Both signals may fire, but die is guarded.
	other.die()
	die()

func spawn_floating_text(points, e_name):
	var text_instance = floating_text_scene.instantiate()
	var display_text = "+" + str(points) + " " + e_name
	
	# Tentukan warna teks berdasarkan tipe (Opsional, biar keren)
	var text_color = Color.WHITE
	if points >= 15: text_color = Color(0.216, 0.137, 0.369, 1.0)
	elif points >= 12: text_color = Color(0.592, 0.0, 0.0, 1.0)  
	elif points >= 8: text_color = Color(0.619, 0.149, 0.392, 1)       
	elif points >= 5: text_color = Color(0.996, 0.909, 0.572, 1)    
	else: text_color = Color(0.478, 0.937, 1, 1)              
	
	text_instance.global_position = global_position
	text_instance.global_position.x += randf_range(-20, 20)
	
	get_tree().current_scene.add_child(text_instance)
	text_instance.start_animation(display_text, text_color)

func spawn_powerup_chance():
	if randf() <= 0.15: 
		spawn_powerup()

func spawn_powerup():
	var powerup = powerup_scene.instantiate()
	powerup.global_position = global_position
	
	var player = get_tree().current_scene.get_node("CharacterBody2D")
	
	var random_type = randi() % 7

	# reroll yahaha -kaiser
	while (
		(random_type == 0 and player.has_shield) or
		(random_type == 5 and player.has_second_wind)
	):
		random_type = randi() % 7
	
	powerup.current_type = random_type
	
	if enemy_type == Type.BOMBER or enemy_type == Type.RBOMBER:
		powerup.apply_xray_effect = true
		
	get_tree().current_scene.call_deferred("add_child", powerup)
		
func exploded():
	var explosion = explosion_scene.instantiate()
	explosion.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", explosion)
	
