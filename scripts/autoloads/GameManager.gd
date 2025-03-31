extends Node

signal battle_started
signal battle_finished
signal dialogue_started
signal dialogue_finished

#SETTINGS
var auto_roll: bool = false #for dice auto_rolling

enum GameStates {TEXT, ADVENTURE, BATTLE}
enum CharStates { IDLE, MOVING, DEAD, DIALOGUE, BATTLE }
enum BattleStat {DAMAGE, ARMOR, MANA, ATTACK_COOLDOWN, CRIT_CHANCE, CRIT_MULTI }

var game_state: GameStates = GameStates.TEXT

var debug_label

var player_health
var player_max_health
var player_stats: CharStats:
	set(value):
		player_stats = value
		cap_health()
var player_damage: 
	get(): return player_stats.get_default_damage()

#called from a visual scene (or from main if currently text scene)
func init_battle(player_ref, enemy_ref):
	player_ref.current_state = CharStates.BATTLE
	enemy_ref.current_state = CharStates.BATTLE
	game_state = GameStates.BATTLE
	battle_started.emit(player_ref, enemy_ref) #caught by battle_handler in main
	
#called from a battle_main (battle scene)
func finish_battle(player_ref, enemy_ref, has_player_won: bool):
	if has_player_won: 
		player_ref.current_state = CharStates.IDLE
		enemy_ref.current_state = CharStates.DEAD
	else:
		player_ref.current_state = CharStates.DEAD
		enemy_ref.current_state = CharStates.IDLE
	game_state = GameStates.ADVENTURE
	battle_finished.emit(player_ref, enemy_ref, has_player_won) #caught by battle_handler and visual scene
	
func init_dialogue(player_ref, speaker_ref, dialogue_name, forced: bool = false):
	if player_ref.current_state == CharStates.DIALOGUE and !forced:
		await dialogue_finished
	player_ref.current_state = CharStates.DIALOGUE
	if speaker_ref.get("current_state"):
		speaker_ref.current_state = CharStates.DIALOGUE
	dialogue_started.emit(player_ref, speaker_ref, dialogue_name)
	
#called from the dialogue scene
func finish_dialogue(player_ref, speaker_ref, dialogue):
	var dialogue_name = dialogue.dialogue_name
	var results = dialogue.results
	dialogue.queue_free()
	player_ref.current_state = CharStates.IDLE
	speaker_ref.current_state = CharStates.IDLE
	dialogue_finished.emit(dialogue_name, results)
	
func _on_skill_changed(skill: String, value: int) -> void:
	var skill_enum = CharStats.get_stat_enum_value(skill)
	if skill_enum == -1:
		push_error("Invalid skill name: " + skill)
		return
	player_stats.stats[skill_enum] += value
	if skill_enum == CharStats.Stat.ENDURANCE:
		if player_health == player_max_health:
			cap_health()
	player_stats.skill_changed.emit()
	
			
func cap_health():
	player_health = player_stats.get_default_health()
	player_max_health = player_health
	

	
			
	
