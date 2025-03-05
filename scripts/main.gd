extends Node3D

var transition_scene = load("res://scenes/transition_scene.tscn")
var battle_scene = load("res://scenes/battle.tscn")

@export var player_stats: CharacterStats #we will move that to the autoload
@export var first_scene: PackedScene

var current_scene = null

func _ready():
	GameManager.battle_started.connect(_on_battle_started)
	GameManager.player_stats = player_stats
	GameManager.player_health = player_stats.get_default_health()
	var s = first_scene.instantiate()
	add_child(s)
	current_scene = s

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()
		
func _on_battle_started(player_scene, enemy_scene):
	var battle = battle_scene.instantiate()
	battle.player_scene = player_scene
	battle.enemy_scene = enemy_scene
	
	battle.player_stats = player_stats
	battle.battle_finished.connect(GameManager._on_battle_finished)
	get_tree().root.add_child(battle)
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
