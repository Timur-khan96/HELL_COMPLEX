extends Node

signal battle_started

enum GameStates {ADVENTURE, BATTLE}
var game_state: GameStates

var player_health
var player_stats: CharacterStats

func init_battle(player_ref, enemy_ref):
	game_state = GameStates.BATTLE
	battle_started.emit(player_ref, enemy_ref)
	
func _on_battle_finished():
	game_state = GameStates.ADVENTURE
