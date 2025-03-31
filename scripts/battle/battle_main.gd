extends Control

var screen_size: Vector2
@onready var attack_cd_label = %attack_cd_label
@onready var battle_grid = %battle_grid
@onready var battle_log = %battle_log

var enemy_scene: BasicCombatant = null
var player_scene: Player = null

var turn_order = [] #for match three greed

func _ready():
	battle_grid.got_matches.connect(_on_matches_found)
	player_scene.attacked.connect(_on_player_attacked)
	enemy_scene.attacked.connect(_on_enemy_attacked)
	player_scene.dead.connect(_on_dead)
	enemy_scene.dead.connect(_on_dead)
	update_stat_labels()
	player_scene.attack_timer.start(player_scene.battle_stats[GameManager.BattleStat.ATTACK_COOLDOWN])
	enemy_scene.attack_timer.start(enemy_scene.battle_stats[GameManager.BattleStat.ATTACK_COOLDOWN])
	
	turn_order.append(player_scene)
	if enemy_scene.character_data.is_swapping:
		#TO DO: CHANGE ORDERING LOGIC FOR MULTIPLE ENEMIES
		var enemy_dex = enemy_scene.character_data.stats.stats[CharStats.Stat.DEXTERITY]
		if player_scene.stats.stats[CharStats.Stat.DEXTERITY] > enemy_dex:
			turn_order.append(enemy_scene)
		else:
			turn_order.push_front(enemy_scene)
	battle_grid.turn_made.connect(set_turn)
	set_turn()
	
func set_turn():
	#await get_tree().create_timer(1.0).timeout
	battle_log.text += "Turn switched \n"
	if battle_grid:
		var current = turn_order.pop_front()
		battle_grid.current_player = current
		turn_order.push_back(current)
	
func _process(_delta):
	attack_cd_label.text = str(int(player_scene.attack_timer.time_left))
	
func _on_enemy_attacked(_attack_object, damage):
	player_scene.hit(damage)
	reset_armor_info_after_enemy_attack()
		
func _on_player_attacked(_attacked_object, damage):
	enemy_scene.hit(damage)
	reset_label_colors()
	update_stat_labels()
		
func _on_dead(dead_battler): #TO DO CHANGE THAT FOR MULTIPLE CHARACTERS
	if dead_battler is Player: finish_battle(false)
	else: finish_battle(true)
		
func finish_battle(has_player_won: bool):
	battle_grid.queue_free()
	await get_tree().create_timer(1.0).timeout
	GameManager.finish_battle(player_scene, enemy_scene, has_player_won)
	queue_free()
	
func _on_matches_found(matches: Dictionary):
	var current_player = battle_grid.current_player
	if current_player == null:
		battle_log.text += "Nobody got" + str(matches) + "\n"
	else:
		var pbs = current_player.battle_stats
		var who = ""
		var is_player = current_player is Player
		if is_player: who = "Player"
		else: who = "Enemy"
		for type in matches:
			if matches[type] == 0: continue
			battle_log.text += who + " got " + type + " +" + str(matches[type]) + "\n"
			match type:
				"red": 
					pbs[GameManager.BattleStat.DAMAGE] += matches[type]
					if is_player and %damage_label.has_theme_color_override("font_color"):
						%damage_label.add_theme_color_override("font_color", Color.LIME_GREEN)
				"blue": 
					pbs[GameManager.BattleStat.ARMOR] += matches[type]
					if is_player and !%armor_label.has_theme_color_override("font_color"):
						%armor_label.add_theme_color_override("font_color", Color.LIME_GREEN)
				"green": 
					pbs[GameManager.BattleStat.CRIT_CHANCE] += matches[type] * 0.01
					if is_player and !%crit_chance_label.has_theme_color_override("font_color"):
						%crit_chance_label.add_theme_color_override("font_color", Color.LIME_GREEN)
				"yellow": pbs[GameManager.BattleStat.MANA] += matches[type]
				"orange": 
					current_player.update_attack_timer(matches[type] * 0.1)
					if is_player and !%attack_cd_label.has_theme_color_override("font_color"):
						%attack_cd_label.add_theme_color_override("font_color", Color.LIME_GREEN)
				"purple": 
					pbs[GameManager.BattleStat.CRIT_MULTI] += matches[type] * 0.1
					if is_player and !%crit_damage_label.has_theme_color_override("font_color"):
						%crit_damage_label.add_theme_color_override("font_color", Color.LIME_GREEN)
			update_stat_labels()
			
func update_stat_labels():
	var stats = player_scene.battle_stats
	%damage_label.text = str(stats[GameManager.BattleStat.DAMAGE])
	%armor_label.text = str(stats[GameManager.BattleStat.ARMOR])
	%mana_label.text = str(stats[GameManager.BattleStat.MANA])
	%crit_chance_label.text = str(stats[GameManager.BattleStat.CRIT_CHANCE])
	%crit_damage_label.text = str(stats[GameManager.BattleStat.CRIT_MULTI])

func reset_armor_info_after_enemy_attack():
	%armor_label.text = str(player_scene.get_armor())
	%armor_label.remove_theme_color_override("font_color")
	
func reset_label_colors():
	%damage_label.remove_theme_color_override("font_color")
	%crit_chance_label.remove_theme_color_override("font_color")
	%crit_damage_label.remove_theme_color_override("font_color")
	%attack_cd_label.remove_theme_color_override("font_color")
