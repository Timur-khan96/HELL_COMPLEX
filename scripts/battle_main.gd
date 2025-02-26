extends Node2D

enum BATTLE_STATE {STARTING, GOING, FINISHED}
var battle_state: BATTLE_STATE = BATTLE_STATE.STARTING

var screen_size: Vector2
@onready var battle_grid = $battle_grid
@onready var below_grid_UI = $below_grid_UI
@onready var fake_grid = %fake_grid #this one for the bars alignment in hbox

@export var player_stats: CharacterStats
@export var enemy_stats: CharacterStats

var player_battle_stats: Dictionary
var enemy_battle_stats: Dictionary

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit() #TO DO MOVE THIS SOMEWHERE ELSE

func _ready():
	screen_size = DisplayServer.screen_get_size()
	get_viewport().size = screen_size
	battle_grid.position.x = (screen_size.x - (screen_size.x / 2)) / 2
	below_grid_UI.position.x = battle_grid.position.x
	below_grid_UI.position.x += battle_grid.GRID_COLS * battle_grid.CELL_SIZE / 2
	below_grid_UI.position.y = battle_grid.GRID_ROWS * battle_grid.CELL_SIZE
	fake_grid.custom_minimum_size.x = battle_grid.GRID_COLS * battle_grid.CELL_SIZE
	
	battle_grid.got_matches.connect(_on_matches_found)
	player_battle_stats = player_stats.get_default_battle_stats()
	enemy_battle_stats = enemy_stats.get_default_battle_stats()
	update_stat_labels()
	
	
func _process(delta):
	if battle_state == BATTLE_STATE.GOING:
		player_battle_stats.attack_cooldown -= delta
		if player_battle_stats.attack_cooldown <= 0:
			var p = player_battle_stats
			if randf() <= p.crit_chance:
				enemy_battle_stats.health -= (p.damage * p.crit_multi) - enemy_battle_stats.armor
			else:
				enemy_battle_stats.health -= p.damage - enemy_battle_stats.armor
			if enemy_battle_stats.health <= 0:
				update_health(%enemy_health, 0)
				finish_battle(true)
			else:
				player_stats.reset_after_attack(player_battle_stats)
				reset_label_colors(false)
				update_health(%enemy_health, enemy_battle_stats.health)
				update_stat_labels()
		enemy_battle_stats.attack_cooldown -= delta
		if enemy_battle_stats.attack_cooldown <= 0:
			var e = enemy_battle_stats
			if randf() <= e.crit_chance:
				player_battle_stats.health -= (e.damage * e.crit_multi) - player_battle_stats.armor
			else:
				player_battle_stats.health -= e.damage - player_battle_stats.armor
			if player_battle_stats.health <= 0:
				update_health(%player_health, 0)
				finish_battle(false)
			else:
				update_health(%player_health, player_battle_stats.health)
				enemy_stats.reset_after_attack(enemy_battle_stats)
				player_stats.reset_after_hit(player_battle_stats)
				reset_label_colors(true)
		update_attack_bar(%player_attack_bar, player_battle_stats.attack_cooldown)
		update_attack_bar(%enemy_attack_bar, enemy_battle_stats.attack_cooldown)
		
func finish_battle(has_player_won: bool):
	battle_state = BATTLE_STATE.FINISHED
	battle_grid.queue_free()
	%battle_result.visible = true
	if has_player_won:
		%battle_result.text = "You win!"
	else:
		%battle_result.text = "You lose!"
	
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
	%player_health.max_value = player_battle_stats.health
	update_health(%player_health, player_battle_stats.health)
	%enemy_health.max_value = enemy_battle_stats.health
	update_health(%enemy_health, enemy_battle_stats.health)
	%player_attack_bar.max_value = player_battle_stats.attack_cooldown
	update_attack_bar(%player_attack_bar, player_battle_stats.attack_cooldown)
	%enemy_attack_bar.max_value = enemy_battle_stats.attack_cooldown
	update_attack_bar(%enemy_attack_bar, enemy_battle_stats.attack_cooldown)
	battle_state = BATTLE_STATE.GOING
	$begin_timer.queue_free()
	
#UPDATING UI FUNCTIONS
func update_health(bar, new_value):
	bar.value = new_value
	
func update_attack_bar(bar, new_value):
	bar.value = new_value
	#bar.get_node("label").text = str(int(new_value))
	
func update_stat_labels():
	var stats = player_battle_stats
	%damage_label.text = str(stats["damage"])
	%armor_label.text = str(stats["armor"])
	%mana_label.text = str(stats["mana"])
	%crit_chance_label.text = str(stats["crit_chance"])
	%crit_damage_label.text = str(stats["crit_multi"])
	
func reset_label_colors(only_armor: bool):
	if only_armor:
		%armor_label.remove_theme_color_override("font_color")
	else:
		%damage_label.remove_theme_color_override("font_color")
		%crit_chance_label.remove_theme_color_override("font_color")
		%crit_damage_label.remove_theme_color_override("font_color")
