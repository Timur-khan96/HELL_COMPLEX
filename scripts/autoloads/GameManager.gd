extends Node

signal battle_started

enum GameStates {TEXT, ADVENTURE, BATTLE}
var game_state: GameStates = GameStates.TEXT

var debug_label

var player_health
var player_max_health
var player_stats: CharacterStats:
	set(value):
		player_stats = value
		cap_health()

func init_battle(player_ref, enemy_ref):
	game_state = GameStates.BATTLE
	battle_started.emit(player_ref, enemy_ref)
	
func _on_battle_finished():
	game_state = GameStates.ADVENTURE
	
func _on_skill_changed(skill: String, value: int):
	player_stats.stats[skill] += value
	if skill == "endurance":
		if player_health == player_max_health:
			cap_health()
			
func cap_health():
	player_health = player_stats.get_default_health()
	player_max_health = player_health
	
			
	
