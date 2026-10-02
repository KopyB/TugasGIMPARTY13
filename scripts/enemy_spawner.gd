extends Marker2D

const ARENA = preload("res://scripts/arena_geometry.gd")
const GUNBOAT_EDGE_INSET := 192.0
const GUNBOAT_SPACING := 336.0
const GUNBOAT_ROW_GAP := 220.0

var enemy_scene = preload("res://scenes/dummy.tscn")
var obstacle_scene = preload("res://scenes/obstacle.tscn")
var parrot_scene = preload("res://scenes/parrot.tscn")
@onready var spawn_timer = $SpawnTimer

const PACING = preload("res://scripts/voyage_pacing.gd")
var time_elapsed := 0.0
var survival_seconds := 0.0
var wave_counter := 0
var is_spawning_paused := false
var opening_spawn := true

func _ready() -> void:
	add_to_group("spawner_utama")
	spawn_timer.start(PACING.first_spawn_delay(GameData.is_hard_mode))

func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.get("is_dead") == true:
		spawn_timer.stop()
		return
	survival_seconds += delta
	if not is_spawning_paused:
		time_elapsed += delta

func _input(event):
	# Hanya aktif di mode debug editor (opsional, biar aman)
	if not OS.has_feature("editor"):
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_U:
		print("DEBUG: Force Spawning Parrot!")
		var viewport_rect = ARENA.SIZE
		spawn_parrot(viewport_rect)
		
		# Opsional: Jika ingin parrot langsung bawa teman (sesuai logika baru)
		if randf() > 0.5:
			spawn_gunboat_group(viewport_rect)
		else:
			spawn_shark(viewport_rect)
			
func pause_spawning():
	print(">>> SYSTEM: Musuh Biasa PAUSED (Maze Mulai) <<<")
	is_spawning_paused = true # Set flag pause
	spawn_timer.stop()        
	
func resume_spawning() -> void:
	is_spawning_paused = false
	wave_counter += 1
	# Reset only the pressure cycle. Long-term progression survives event breaks.
	time_elapsed = 0.0
	spawn_timer.start(PACING.recovery_delay(GameData.is_hard_mode))

func _on_spawn_timer_timeout() -> void:
	if is_spawning_paused:
		return
	# A soft population cap prevents an invulnerability chain from piling up forever.
	var limit := 42 if GameData.is_hard_mode else 30
	if get_tree().get_nodes_in_group("enemies").size() < limit:
		if opening_spawn:
			spawn_gunboat_group(ARENA.SIZE)
			opening_spawn = false
		else:
			spawn_logic()
	spawn_timer.start(PACING.spawn_interval(survival_seconds, time_elapsed, GameData.is_hard_mode))

func spawn_logic():
	var parrotcheck = get_tree().get_nodes_in_group("parrots").size()
	var viewport_rect = ARENA.SIZE
	
	# Randomizer Tipe Musuh (Total 100%)
	var chance = randi() % 100
	var introduction_time := survival_seconds * (1.5 if GameData.is_hard_mode else 1.0)
	if (chance < 7.5 and introduction_time < 45.0) or (chance >= 35 and chance < 55 and introduction_time < 9.0) or (chance >= 55 and chance < 70 and introduction_time < 16.0) or (chance >= 70 and chance < 85 and introduction_time < 25.0):
		chance = 20 # Keep spawning boats while introducing threats in stages.
	
	
	# TOTAL HARUS 100%. SELALU FOLLOW SUSUNAN LIKE BELOW 
	# 1. PARROT (Sangat Jarang: 7.5%)
	if chance < 7.5 and parrotcheck == 0 and get_tree().get_nodes_in_group("enemies").size() >= 1: 
		spawn_parrot(viewport_rect)
		if randf() > 0.5:
			spawn_gunboat_group(viewport_rect)
		else:
			if randf() > 0.5:
				spawn_bomber(viewport_rect)
			else:
				spawn_rbomber(viewport_rect)
			
	# 2. GUNBOAT (27.5%) -> Range 5 sampai 39
	elif chance < 35: 
		spawn_gunboat_group(viewport_rect)
		
	# 3. BOMBER (20%) -> Range 40 sampai 64
	elif chance < 55: 
		if randf() > 0.5:
			spawn_bomber(viewport_rect)
		else:
			spawn_rbomber(viewport_rect)

	# 4. SHARK (15%) -> Range 65 sampai 79
	elif chance < 70:
		spawn_shark(viewport_rect)
	
	# 5. SIREN (15%) -> Range 85 sampai 89
	elif chance < 85:
		if randf() > 0.5:
			spawn_siren(viewport_rect)
		else:
			spawn_rsiren(viewport_rect)

	# 6. OBSTACLE (Sisanya 15%) -> Range 90 sampai 99
	else: 
		if get_tree().get_nodes_in_group("obstacles").size() >= 24:
			spawn_gunboat_group(viewport_rect)
			return
		if randf() > 0.80:
			spawn_obstacle_row(viewport_rect)
		else:
			spawn_single_obstacle(viewport_rect)
		
# --- TIPE 1A: OBSTACLE SATUAN ---
func spawn_single_obstacle(viewport_rect):
	var obs = obstacle_scene.instantiate()
	
	# Random type (0 = Bones, 1 = Shipwreck)
	var type = randi() % 2
	obs.setup_obstacle(type) 
	
	# Posisi X acak, Y di atas layar
	var spawn_x = randf_range(60, viewport_rect.x - 60)
	obs.global_position = Vector2(spawn_x, -80)
	
	get_tree().current_scene.add_child(obs)
	
# --- TIPE 1B: OBSTACLE PACKED ---
func spawn_obstacle_row(viewport_rect):
	var columns = 8 
	var col_width = viewport_rect.x / columns
	
	# Column: 0-7
	var available_cols = []
	for i in range(columns):
		available_cols.append(i)
	
	available_cols.shuffle()
	
	for i in range(randi_range(3, 6)):
		var col_index = available_cols[i]
		
		var obs = obstacle_scene.instantiate()
		var type = randi() % 2
		obs.setup_obstacle(type) 
		
		var spawn_x = (col_index * col_width) + (col_width / 2)
		var spawn_y = -80 - randf_range(0, 40)
		
		obs.global_position = Vector2(spawn_x, spawn_y)
		get_tree().current_scene.add_child(obs)
		
# --- TIPE 2: GUNBOAT GROUP ---
func spawn_gunboat_group(_viewport_rect):
	var count := 1 if opening_spawn else randi_range(1, 2 if survival_seconds < 40.0 else 3)
	var spacing := randf_range(GUNBOAT_SPACING, 520.0)
	var half_width := float(count - 1) * spacing * 0.5
	var left := GUNBOAT_EDGE_INSET + half_width
	var right := ARENA.SIZE.x - GUNBOAT_EDGE_INSET - half_width
	var positions: Array[Vector2] = []
	var existing: Array[Vector2] = []
	var earliest_y := -180.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.get("enemy_type") == 0 and not enemy.is_queued_for_deletion():
			existing.append(enemy.global_position)
			earliest_y = minf(earliest_y, enemy.global_position.y - GUNBOAT_ROW_GAP - 1.0)
	# Prefer an immediate clear entry row. If crowded, stagger the whole group
	# upstream. Never drop enemies or change the wave timer to resolve overlaps.
	for attempt in range(24):
		var center := randf_range(left, right)
		var y := -180.0 - floorf(float(attempt) / 8.0) * GUNBOAT_ROW_GAP
		positions = _gunboat_positions(count, center, spacing, y)
		if _gunboat_positions_clear(positions, existing):
			break
	if not _gunboat_positions_clear(positions, existing):
		positions = _gunboat_positions(count, randf_range(left, right), spacing, earliest_y)
	for spawn_position in positions:
		var enemy = enemy_scene.instantiate()
		enemy.enemy_type = 0
		enemy.global_position = spawn_position
		get_tree().current_scene.add_child(enemy)

func _gunboat_positions(count: int, center: float, spacing: float, y: float) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for index in range(count):
		result.append(Vector2(center + (float(index) - float(count - 1) * 0.5) * spacing, y))
	return result

func _gunboat_positions_clear(positions: Array[Vector2], existing: Array[Vector2]) -> bool:
	for candidate in positions:
		for other in existing:
			if absf(candidate.x - other.x) < GUNBOAT_SPACING and absf(candidate.y - other.y) < GUNBOAT_ROW_GAP:
				return false
	return true

func _add_entering_enemy(enemy: Node2D, side: String) -> void:
	get_tree().current_scene.add_child(enemy)
	# _ready sets the correct texture, orientation and scale for this type.
	var bounds: Rect2 = ARENA.visual_bounds(enemy)
	if side == "left":
		enemy.global_position.x -= maxf(0.0, bounds.end.x + 24.0)
	elif side == "right":
		enemy.global_position.x += maxf(0.0, ARENA.SIZE.x + 24.0 - bounds.position.x)
	else:
		enemy.global_position.y -= maxf(0.0, bounds.end.y + 24.0)

# --- TIPE 3A: BOMBER DARI KIRI (DEFAULT) ---
func spawn_bomber(viewport_rect):
	# --- LBOMBER (Spawn Sendiri dari Kiri) ---
	var new_enemy = enemy_scene.instantiate()
	new_enemy.enemy_type = 1 # LBomber
		
	var spawn_x = -60 # Di luar layar kiri
	var spawn_y = randf_range(50, viewport_rect.y / 2) 
	
	new_enemy.global_position = Vector2(spawn_x, spawn_y)
	_add_entering_enemy(new_enemy, "left")


# --- TIPE 3B: RBOMBER DARI KANAN (BARU) ---
func spawn_rbomber(viewport_rect):
	var new_enemy = enemy_scene.instantiate()
	new_enemy.enemy_type = 2 # RBOMBER (Sesuai Enum di dummy.gd)
	
	# Spawn di luar layar KANAN
	var spawn_x = viewport_rect.x + 60 
	# Y acak (setengah atas layar)
	var spawn_y = randf_range(50, viewport_rect.y / 2) 
	
	new_enemy.global_position = Vector2(spawn_x, spawn_y)
	_add_entering_enemy(new_enemy, "right")
  
func spawn_parrot(viewport_rect):
	var new_enemy = parrot_scene.instantiate()
	new_enemy.get_child(0).get_child(0).enemy_type = 3
	var spawn_x = 0
	var spawn_y = 0
	
	new_enemy.global_position = Vector2(spawn_x, spawn_y)
	add_child(new_enemy)
	new_enemy.get_child(0).get_child(0).add_to_group("parrots")
	print("Parrots alive: ", get_tree().get_nodes_in_group("parrots").size())

func spawn_shark(viewport_rect):
	var new_enemy = enemy_scene.instantiate()
	new_enemy.enemy_type = 4 # Tipe 4 = TORPEDO SHARK (Sesuai Enum)
	
	# Spawn di sembarang tempat di atas layar atau samping
	var spawn_side = randi() % 3 # 0=Atas, 1=Kiri, 2=Kanan
	var spawn_pos = Vector2.ZERO
	
	if spawn_side == 0: # Atas
		spawn_pos.x = randf_range(50, viewport_rect.x - 50)
		spawn_pos.y = -50
	elif spawn_side == 1: # Kiri
		spawn_pos.x = -50
		spawn_pos.y = randf_range(50, viewport_rect.y / 4)
	else: # Kanan
		spawn_pos.x = viewport_rect.x + 50
		spawn_pos.y = randf_range(50, viewport_rect.y / 4)
		
	new_enemy.global_position = spawn_pos
	_add_entering_enemy(new_enemy, ["top", "left", "right"][spawn_side])

func spawn_siren(viewport_rect):
	var new_enemy = enemy_scene.instantiate()
	new_enemy.enemy_type = 5 # 4 = SIREN

	var spawn_x = -60
	var spawn_y = randf_range(50, viewport_rect.y / 2)
	new_enemy.global_position = Vector2(spawn_x,spawn_y)
	_add_entering_enemy(new_enemy, "left")

func spawn_rsiren(viewport_rect):
	var new_enemy = enemy_scene.instantiate()
	new_enemy.enemy_type = 6 # 5 = RSIREN

	var spawn_x = viewport_rect.x + 60
	var spawn_y = randf_range(50, viewport_rect.y / 2)
	new_enemy.global_position = Vector2(spawn_x,spawn_y)
	_add_entering_enemy(new_enemy, "right")
