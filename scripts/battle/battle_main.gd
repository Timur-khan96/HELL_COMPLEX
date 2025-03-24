extends Node2D

enum BATTLE_STATE {STARTING, GOING, FINISHED}
var battle_state: BATTLE_STATE = BATTLE_STATE.STARTING

var screen_size: Vector2
@onready var battle_grid = $battle_grid
@onready var above_grid_UI = $above_grid_UI
@onready var attack_cd_label = %attack_cd_label


var enemy_scene: BasicCombatant = null
var player_scene: Player = null

func _ready():
	screen_size = get_viewport().size
	battle_grid.position.x = (screen_size.x - (screen_size.x / 2)) / 2
	battle_grid.position.x += battle_grid.CELL_SIZE + (battle_grid.CELL_SIZE / 2)
	battle_grid.position.y = 176
	above_grid_UI.position.x = screen_size.x / 2
	
	battle_grid.got_matches.connect(_on_matches_found)
	player_scene.attacked.connect(_on_player_attacked)
	enemy_scene.attacked.connect(_on_enemy_attacked)
	player_scene.dead.connect(_on_dead)
	enemy_scene.dead.connect(_on_dead)
	update_stat_labels()
	
func _process(_delta):
	attack_cd_label.text = str(int(player_scene.attack_timer.time_left))
	
func _on_enemy_attacked(_attack_object, damage):
	player_scene.hit(damage)
	reset_armor_info_after_enemy_attack()
		
func _on_player_attacked(_attacked_object, damage):
	enemy_scene.hit(damage)
	reset_label_colors()
	update_stat_labels()
		
func _on_dead(dead_battler):
	if dead_battler is Player: finish_battle(false)
	else: finish_battle(true)
		
func finish_battle(_has_player_won: bool):
	battle_state = BATTLE_STATE.FINISHED
	battle_grid.queue_free()
	$end_timer.start()
	
func _on_matches_found(matches: Dictionary):
	for type in matches:
		var pbs = player_scene.battle_stats
		if matches[type] == 0: continue
		match type:
			"red": 
				pbs[GameManager.BattleStat.DAMAGE] += matches[type]
				if !%damage_label.has_theme_color_override("font_color"):
					%damage_label.add_theme_color_override("font_color", Color.LIME_GREEN)
			"blue": 
				pbs[GameManager.BattleStat.ARMOR] += matches[type]
				if !%armor_label.has_theme_color_override("font_color"):
					%armor_label.add_theme_color_override("font_color", Color.LIME_GREEN)
			"green": 
				pbs[GameManager.BattleStat.CRIT_CHANCE] += matches[type] * 0.01
				if !%crit_chance_label.has_theme_color_override("font_color"):
					%crit_chance_label.add_theme_color_override("font_color", Color.LIME_GREEN)
			"yellow": pbs[GameManager.BattleStat.MANA] += matches[type]
			"orange": player_scene.update_attack_timer(matches[type] * 0.1)
			"purple": 
				pbs[GameManager.BattleStat.CRIT_MULTI] += matches[type] * 0.1
				if !%crit_damage_label.has_theme_color_override("font_color"):
					%crit_damage_label.add_theme_color_override("font_color", Color.LIME_GREEN)
		update_stat_labels()
			
	
func _on_begin_timer_timeout():
	above_grid_UI.show()
	player_scene.attack_timer.start(player_scene.battle_stats[GameManager.BattleStat.ATTACK_COOLDOWN])
	enemy_scene.attack_timer.start(enemy_scene.battle_stats[GameManager.BattleStat.ATTACK_COOLDOWN])
	battle_state = BATTLE_STATE.GOING
	$begin_timer.queue_free()
	
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

func _on_end_timer_timeout():
	GameManager.finish_battle(player_scene, enemy_scene)
	queue_free()
