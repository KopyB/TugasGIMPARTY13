extends Node

# STATS
var is_hard_mode: bool = false
var has_played_game: bool = false
var powerups_collected: int = 0
var revives_count: int = 0
var enemies_killed: int = 0
var highscore: int = 0

# STATS TEMPORARY 
var kraken_session_kills: int = 0

var unlocked_achievements = []
const SAVE_PATH = "user://savegame.cfg"

func _ready():
	load_stats()
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		highscore = config.get_value("game", "highscore", 0)
		
func check_score_achievements(final_score: int):
	if final_score > highscore:
		highscore = final_score
	
	if highscore >= 200: check_and_unlock("score_200", "Good amount for starter")
	if highscore >= 800: check_and_unlock("score_800", "Point Master")
	if highscore >= 1500: check_and_unlock("score_1500", "The Collector")
	if highscore >= 4000: check_and_unlock("score_4000", "Point Grinder")
	if highscore >= 10000: check_and_unlock("score_10000", "Unstoppable")
	if highscore >= 50000: check_and_unlock("score_50000", "TOTAL POINT DEATH")
	if final_score <= 5: check_and_unlock("are_you_kidding", "Are you kidding me?")
func check_and_unlock(id: String, title: String):
	if not id in unlocked_achievements:
		unlocked_achievements.append(id)
		save_stats()
		
		Notify.show_achievement(title)
		print("Achievement Unlocked: ", title)

func save_stats():
	var config = ConfigFile.new()
	config.load(SAVE_PATH) 
	
	# All stats put here (sure)
	config.set_value("stats", "has_played", has_played_game)
	config.set_value("stats", "powerups_collected", powerups_collected)
	config.set_value("stats", "revives_count", revives_count)
	config.set_value("stats", "enemies_killed", enemies_killed)
	config.set_value("stats", "unlocked_list", unlocked_achievements)
	
	
	config.save(SAVE_PATH)

# load ach
func load_stats():
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	
	if err == OK:
		has_played_game = config.get_value("stats", "has_played", false)
		powerups_collected = config.get_value("stats", "powerups_collected", 0)
		revives_count = config.get_value("stats", "revives_count", 0)
		enemies_killed = config.get_value("stats", "enemies_killed", 0)
		unlocked_achievements = config.get_value("stats", "unlocked_list", [])

func reset_all_data():
	if FileAccess.file_exists(SAVE_PATH):
		var dir = DirAccess.open("user://")
		dir.remove("savegame.cfg")
		print("file udh dihapus.")
	
	highscore = 0
	has_played_game = false
	powerups_collected = 0
	revives_count = 0
	enemies_killed = 0
	kraken_session_kills = 0
	unlocked_achievements = []
	is_hard_mode = false 
	
	var config = ConfigFile.new()
	config.set_value("game", "highscore", 0) 
	config.set_value("stats", "has_played", false)
	config.set_value("stats", "powerups_collected", 0)
	config.set_value("stats", "revives_count", 0)
	config.set_value("stats", "enemies_killed", 0)
	config.set_value("stats", "unlocked_list", [])
	
	config.save(SAVE_PATH)
	
