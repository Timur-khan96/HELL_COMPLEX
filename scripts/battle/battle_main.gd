extends Node2D

signal battle_finished

enum BATTLE_STATE {STARTING, GOING, FINISHED}
var battle_state: BATTLE_STATE = BATTLE_STATE.STARTING

var screen_size: Vector2
@onready var battle_grid = $battle_grid
@onready var below_grid_UI = $below_grid_UI

var player_stats: CharacterStats
var enemy_stats: CharacterStats

var player_battle_stats: Dictionary
var enemy_battle_stats: Dictionary

var enemy_scene = null
var player_scene = null

func _ready():
	screen_size = get_viewport().size
	battle_grid.position.x = (screen_size.x - (screen_size.x / 2)) / 2
	below_grid_UI.position.x = battle_grid.position.x
	below_grid_UI.position.x += battle_grid.GRID_COLS * battle_grid.CELL_SIZE / 2
	below_grid_UI.position.y = battle_grid.GRID_ROWS * battle_grid.CELL_SIZE
	
	battle_grid.got_matches.connect(_on_matches_found)
	enemy_stats = enemy_scene.stats #player stats are given from main
	player_battle_stats = player_stats.get_default_battle_stats()
	enemy_battle_stats = enemy_stats.get_default_battle_stats()
	update_stat_labels()
	
func _process(delta):
	if battle_state == BATTLE_STATE.GOING:
		player_battle_stats.attack_cooldown -= delta
		if player_battle_stats.attack_cooldown <= 0:
			player_scene.play_anim("attack")
			var p = player_battle_stats
			if randf() <= p.crit_chance:
				enemy_scene.hit((p.damage * p.crit_multi) - enemy_battle_stats.armor)
			else:
				enemy_scene.hit(p.damage - enemy_battle_stats.armor)
			if enemy_scene.health <= 0:
				finish_battle(true)
			else:
				player_stats.reset_after_attack(player_battle_stats)
				reset_label_colors()
				update_stat_labels()
				
				
		enemy_battle_stats.attack_cooldown -= delta
		if enemy_battle_stats.attack_cooldown <= 0:
			enemy_scene.play_anim("attack")
			var e = enemy_battle_stats
			if randf() <= e.crit_chance:
				player_scene.hit((e.damage * e.crit_multi) - player_battle_stats.armor)
			else:
				player_scene.hit(e.damage - player_battle_stats.armor)
			if player_scene.health <= 0:
				finish_battle(false)
			else:
				enemy_stats.reset_after_attack(enemy_battle_stats)
				reset_after_player_hit()
		update_attack_bar(%player_attack_bar, player_battle_stats.attack_cooldown)
		update_attack_bar(%enemy_attack_bar, enemy_battle_stats.attack_cooldown)
		
func finish_battle(_has_player_won: bool):
	battle_state = BATTLE_STATE.FINISHED
	battle_grid.queue_free()
	$end_timer.start()
	
func _on_matches_found(matches: Dictionary):
	for type in matches:
		if matches[type] == 0: continue
		match type:
			"red": 
				player_battle_stats["damage"] += matches[type]
				if !%damage_label.has_theme_color_override("font_color"):
					%damage_label.add_theme_color_override("font_color", Color.LIME_GREEN)
			"blue": 
				player_battle_stats["armor"] += matches[type]
				if !%armor_label.has_theme_color_override("font_color"):
					%armor_label.add_theme_color_override("font_color", Color.LIME_GREEN)
			"green": 
				player_battle_stats["crit_chance"] += matches[type] * 0.01
				if !%crit_chance_label.has_theme_color_override("font_color"):
					%crit_chance_label.add_theme_color_override("font_color", Color.LIME_GREEN)
			"yellow": player_battle_stats["mana"] += matches[type]
			"orange": player_battle_stats["attack_cooldown"] -= matches[type] * 0.1
			"purple": 
				player_battle_stats["crit_multi"] += matches[type] * 0.1
				if !%crit_damage_label.has_theme_color_override("font_color"):
					%crit_damage_label.add_theme_color_override("font_color", Color.LIME_GREEN)
		update_stat_labels()
			
	
func _on_begin_timer_timeout():
	below_grid_UI.show()
	%player_attack_bar.max_value = player_battle_stats.attack_cooldown
	update_attack_bar(%player_attack_bar, player_battle_stats.attack_cooldown)
	%enemy_attack_bar.max_value = enemy_battle_stats.attack_cooldown
	update_attack_bar(%enemy_attack_bar, enemy_battle_stats.attack_cooldown)
	battle_state = BATTLE_STATE.GOING
	$begin_timer.queue_free()
	
func update_attack_bar(bar, new_value):
	bar.value = new_value
	
func update_stat_labels():
	var stats = player_battle_stats
	%damage_label.text = str(stats["damage"])
	%armor_label.text = str(stats["armor"])
	%mana_label.text = str(stats["mana"])
	%crit_chance_label.text = str(stats["crit_chance"])
	%crit_damage_label.text = str(stats["crit_multi"])

func reset_after_player_hit():
	player_stats.reset_after_hit(player_battle_stats)
	%armor_label.text = str(player_battle_stats["armor"])
	%armor_label.remove_theme_color_override("font_color")
	
func reset_label_colors():
		%damage_label.remove_theme_color_override("font_color")
		%crit_chance_label.remove_theme_color_override("font_color")
		%crit_damage_label.remove_theme_color_override("font_color")

func _on_end_timer_timeout():
	battle_finished.emit()
	queue_free()
