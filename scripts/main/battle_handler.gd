extends Node
#initializer and finisher of the battle scenes

var battle_scene = load("res://scenes/main/battle.tscn")
var player_initial_position
var enemy_initial_position

var player_battle_threat: String
var hidden_objects = [] 

func _ready():
	GameManager.battle_finished.connect(_on_battle_finished)

func _on_battle_started(player_scene, enemy_scene, cam):
	var battle = battle_scene.instantiate()
	battle.player_scene = player_scene
	battle.enemy_scene = enemy_scene
	
	add_child(battle)
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
	
	var player_sprite = player_scene.get_node("Sprite3D")
	player_sprite.flip_h = false
	#player_sprite.no_depth_test = true
	#player_sprite.render_priority = 1
	
	#var enemy_sprite = enemy_scene.get_node("Sprite3D")
	#enemy_sprite.no_depth_test = true
	#enemy_sprite.render_priority = 1

	player_initial_position = player_scene.global_position
	enemy_initial_position = enemy_scene.global_position
	player_battle_threat = enemy_scene.player_battle_threat
	
	var tween = create_tween()
	tween.tween_property(player_scene, "position", player_pos, 1).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(_battle_position_reached.bind(player_scene))
	var tween_enemy = create_tween()
	tween_enemy.tween_property(enemy_scene, "position", enemy_pos, 1).set_trans(Tween.TRANS_SINE)
	tween_enemy.tween_callback(_battle_position_reached.bind(enemy_scene))
	player_scene.play_anim("move")
	enemy_scene.play_anim("move")
	
func _battle_position_reached(battler): #change that for battle ending
	battler.stop_anim("move")
	battler.play_anim("fight_begin")
	
	var colliding_objects = _get_colliding_objects(battler)
	for obj in colliding_objects:
		if obj.is_in_group("obstructing"):
			hidden_objects.append(obj)
			obj.hide()
			
	if battler is Player: battler.say(tr(player_battle_threat))
	else: battler.say(tr(battler.attack_reaction))
		
func _get_colliding_objects(character):
	var space_state = character.get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = character.get_node("CollisionShape3D").shape
	query.transform = character.global_transform
	#query.collision_mask = 1

	var results = space_state.intersect_shape(query, 10)
	var colliders = []
	for result in results:
		colliders.append(result.collider)
	
	return colliders
		
func _on_battle_finished(player_scene, enemy_scene, _has_player_won):
	var player_sprite = player_scene.get_node("Sprite3D")
	player_sprite.no_depth_test = false
	player_sprite.render_priority = 0
	
	var enemy_sprite = enemy_scene.get_node("Sprite3D")
	enemy_sprite.no_depth_test = false
	enemy_sprite.render_priority = 0
	
	var tween = create_tween()
	tween.tween_property(player_scene, "position", player_initial_position, 1).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(_initial_position_reached.bind(player_scene))
	var tween_enemy = create_tween()
	tween_enemy.tween_property(enemy_scene, "position", enemy_initial_position, 1).set_trans(Tween.TRANS_SINE)
	tween_enemy.tween_callback(_initial_position_reached.bind(enemy_scene))
	player_scene.play_anim("move")
	enemy_scene.play_anim("move")
	
	for obj in hidden_objects:
		obj.show()
	
func _initial_position_reached(battler):
	battler.stop_anim("move")
	battler.stop_anim("fight_begin")
