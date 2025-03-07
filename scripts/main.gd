extends Node3D

#var transition_scene = load("res://scenes/transition_scene.tscn")
var battle_scene = load("res://scenes/battle.tscn")
var text_scene = load("res://scenes/text_scene.tscn")

@onready var menu = $main_menu
var current_scene = null #battle and menu do not change this

func _on_start_button_pressed():
	if get_tree().paused:
		get_tree().paused = false
		menu.hide()
	else:
		menu.hide()
		%start_button.text = tr("CONTINUE") #change in translation
		start_game()
		
func _on_exit_button_pressed(): get_tree().quit()
	
func start_game():
	GameManager.player_stats = CharacterStats.new()
	GameManager.battle_started.connect(_on_battle_started)
	GameManager.debug_label = %debug_label
	_on_text_scene_finished("intro")
	#var s = text_scene.instantiate()
	#add_child(s)
	#s.init_scene_from_file("intro")
	#current_scene = s
	#s.scene_finished.connect(_on_text_scene_finished)
	#s.skill_changed.connect(GameManager._on_skill_changed)
	
func set_ambush_dic():
	return {
		"scenes": {"0": {"text": {"ru": "Вы попали в засаду!", "en": "You were ambushed!"}}}
	}
	
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().paused = true
		menu.move_to_front()
		menu.show()
		
func _on_text_scene_finished(scene_name):
	if current_scene != null: current_scene.queue_free()
	if scene_name == "intro":
		GameManager.game_state = GameManager.GameStates.ADVENTURE
		var s = load("res://scenes/town_square_scene.tscn").instantiate()
		add_child(s)
		current_scene = s
		
func _on_battle_started(player_scene, enemy_scene):
	var battle = battle_scene.instantiate()
	battle.player_scene = player_scene
	battle.enemy_scene = enemy_scene
	
	battle.player_stats = GameManager.player_stats
	battle.battle_finished.connect(GameManager._on_battle_finished)
	battle.battle_finished.connect(player_scene._on_battle_finished)
	add_child(battle)
	var cam = current_scene.get_node("Camera3D")
	var player_2d = battle.get_node("player_position").global_position
	var enemy_2d = battle.get_node("enemy_position").global_position

	var player_ray_origin = cam.project_ray_origin(player_2d)
	var enemy_ray_origin = cam.project_ray_origin(enemy_2d)

	var player_depth = (player_scene.global_position - cam.global_position).length()
	var enemy_depth = (enemy_scene.global_position - cam.global_position).length()

	var player_pos = player_ray_origin + cam.project_ray_normal(player_2d) * player_depth
	var enemy_pos = enemy_ray_origin + cam.project_ray_normal(enemy_2d) * enemy_depth
	
	player_pos.y = player_scene.global_position.y
	enemy_pos.y = enemy_scene.global_position.y

	# Tween the objects to the calculated positions
	var tween = create_tween()
	tween.tween_property(player_scene, "position", player_pos, 1).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(_battle_position_reached.bind(player_scene))
	var tween_enemy = create_tween()
	tween_enemy.tween_property(enemy_scene, "position", enemy_pos, 1).set_trans(Tween.TRANS_SINE)
	tween_enemy.tween_callback(_battle_position_reached.bind(enemy_scene))
	player_scene.play_anim("move")
	enemy_scene.play_anim("move")
	
func _battle_position_reached(battler):
	if battler is Player: 
		battler.stop_anim("move")
		battler.play_anim("fight_begin")
	else:
		battler.stop_anim("move")
		if battler.has_anim("fight_begin"): battler.play_anim("fight_begin")
	
#func _init_transition(next_scene_name):
	#var t = transition_scene.instantiate()
	#t.transition_midway.connect(_on_transition_midway)
	#t.transition_finished.connect(_on_transition_finished)
	#get_tree().root.add_child(t)
	#current_scene.process_mode = PROCESS_MODE_DISABLED
	#next_scene = load("res://scenes/" + next_scene_name + ".tscn")
	#
#func _on_transition_finished():
	#current_scene.process_mode = PROCESS_MODE_INHERIT
	#
#func _on_transition_midway():
	#if next_scene == battle_scene:
		#var temp = current_scene
		#var b = battle_scene.instantiate()
		#get_tree().root.add_child(b)
		#current_scene = b
		#current_scene.process_mode = PROCESS_MODE_DISABLED
		#next_scene = temp
func _on_eng_button_pressed(): 
	TranslationServer.set_locale("en")
	if current_scene is TextScene: current_scene.update_locale()

func _on_rus_button_pressed(): 
	TranslationServer.set_locale("ru")
	if current_scene is TextScene: current_scene.update_locale()
