extends Node3D
const text_scene = preload("res://scenes/main/text_scene.tscn")
const battle_encounter = preload("res://scenes/encounter_scene.tscn")

@onready var menu = $main_menu
@onready var battle_handler = $battle_handler
@onready var dice_handler = $dice_handler

var current_scene = null #battle and menu do not change this

func start_game():
	GameManager.player_stats = CharStats.new()
	GameManager.battle_started.connect(_on_battle_started)
	GameManager.debug_label = %debug_label
	init_visual_scene("town_square_scene")
	#init_text_scene("intro")
	
#func set_ambush_dic():
	#return {
		#"scenes": {"0": {"text": {"ru": "Вы попали в засаду!", "en": "You were ambushed!"}}}
	#}
	
func init_text_scene(scene_name: String):
	GameManager.game_state = GameManager.GameStates.TEXT
	var s = text_scene.instantiate()
	add_child(s)
	s.init_scene_from_file(scene_name)
	current_scene = s
	s.scene_finished.connect(_on_text_scene_finished)
	
func init_visual_scene(scene_name: String):
	GameManager.game_state = GameManager.GameStates.ADVENTURE
	var s = load("res://scenes/" + scene_name + ".tscn").instantiate()
	add_child(s)
	s.scene_finished.connect(_on_visual_scene_finished)
	s.dice_check.connect(dice_handler.init_dice_check)
	s.dice_contested.connect(dice_handler.init_dice_contested)
	current_scene = s
	
func init_battle_encounter(enemy: CombatantData):
	var s = battle_encounter.instantiate()
	s.get_node("basic_combatant").character_data = enemy
	add_child(s)
	current_scene = s
	GameManager.init_battle(s.get_node("player"), s.get_node("basic_combatant"))
	
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().paused = true
		menu.move_to_front()
		menu.show()
		
func _on_text_scene_finished(scene_name: String):
	if current_scene != null: current_scene.queue_free()
	match scene_name:
		"intro": init_visual_scene("town_square_scene")
		
func _on_visual_scene_finished(scene_name: String, scene_states: Dictionary):
	if current_scene != null: current_scene.queue_free()
	match scene_name:
		"town_square_scene":
			#TO DO: CHASING SCENE???
			if scene_states.get("player_left_early_and_started_battle"):
				init_battle_encounter(load("res://custom_resources/guard.tres"))
			elif scene_states.get("player_left_ontime"):
				init_text_scene("escaping_town_square")
			elif scene_states.get("player_started_fight_and_submitted"):
				print("You are getting to prison and then to arena")
			elif scene_states.get("player_died"):
				print("You are going straight to heeeeeeeell")
			else:
				init_text_scene("slavemasters_guild")
			
func _on_battle_started(player, enemy):
	battle_handler._on_battle_started(player, enemy, current_scene.get_node("Camera3D"))
	
func _on_start_button_pressed():
	if get_tree().paused:
		get_tree().paused = false
		menu.hide()
	else:
		menu.hide()
		%start_button.text = tr("CONTINUE")
		start_game()
		
func _on_exit_button_pressed(): get_tree().quit()
		
func _on_eng_button_pressed(): 
	TranslationServer.set_locale("en")
	if current_scene is TextScene: current_scene.update_locale()
	else:
		for c in current_scene.get_children():
			if c is Dialogue:
				c.update_locale()

func _on_rus_button_pressed(): 
	TranslationServer.set_locale("ru")
	if current_scene is TextScene: current_scene.update_locale()
	else:
		for c in current_scene.get_children():
			if c is Dialogue:
				c.update_locale()
