extends Node3D

signal scene_finished
signal dice_check(this_scene_reference, roll_id)
signal dice_contested(this_scene_reference, roll_data) #roll_id, player_stat, enemy_stat, enemy_stat_bonus

@onready var camera = $Camera3D
@onready var main_guard = $guard
@onready var player: Player = $player
@onready var first_trash = $Trash/trash
@onready var elf_girl = $elf_girl
@onready var broom = $broom
@onready var broom_timer = $broom_timer
@onready var old_man = $old_man
var locksmith

var dice_rolling_scene = load("res://scenes/dice_rolling/dice_rolling_scene.tscn")
var passer_by_male = load("res://scenes/characters/passer_by.tscn")
var passer_by_female = load("res://scenes/characters/passer_by_woman.tscn")
var trash = load("res://scenes/interactable/trash.tscn")
var dialogue = load("res://scenes/UI/dialogue.tscn")

var current_dialogue = null #now guard can interrupt that
var passer_by_timer
var passer_by_speed = 2.0

var active_passers = []
var scene_name = "town_square_scene"
var scene_states = {
	"player_took_broom": false,
	"first_warning": false,
	"guard_angry": false,
	"player_in_pillory": false,
	"locksmith_arrived": false,
	"moved_chest": false,
	"tried_moving_chest": false,
	"player_left_early": false,
	"locksmith_dexterity": false, #this two for rolling for lockpick
	"locksmith_charisma": false
	}

func _ready():
	player.attacked.connect(_on_player_attacked)
	player.get_node("VisibleOnScreenNotifier3D").screen_exited.connect(_on_player_exited_scene)
	passer_by_timer = randf_range(2, 4)
	camera.bound_camera(Vector2(10, 8), Vector2(-6, -8)) #TO DO: CHANGE THESE
	main_guard.say(tr("GUARD_LINE_1"), 4.0)
	main_guard.interacted.connect(func(guard): guard.say(tr("WHAT")))
	
	old_man.screen_entered.connect(func(man): man.say(tr("OLD_ELF_CALL"), 4.0))
	old_man.interacted.connect(func(man):
		if scene_states.moved_chest: man.say(tr("WHAT"))
		else: GameManager.init_dialogue(player, man, "town_square_old_elf"))
	
	elf_girl.interacted.connect(
		func(girl):
			if scene_states.locksmith_arrived:
				GameManager.init_dialogue(player, girl, "town_square_elf_girl_ontime")
			else:
				GameManager.init_dialogue(player, girl, "town_square_elf_girl_early"))
	
	first_trash.tree_exited.connect(func(): scene_states.first_warning = true)
	GameManager.dialogue_started.connect(init_dialogue)
	GameManager.dialogue_finished.connect(_on_dialogue_finished)
	GameManager.battle_finished.connect(_on_battle_finished)
	broom_timer.timeout.connect(angry_guard)
	broom.equipped.connect(func():
		if broom_timer: broom_timer.queue_free()
		scene_states.player_took_broom = true)

func _process(delta):
	manage_passers(delta)
	if scene_states.locksmith_arrived:
		pass
	else:
		if $Trash.get_child_count() >= 2 and !scene_states.first_warning and !scene_states.player_took_broom:
			first_guard_warning()
		elif $Trash.get_child_count() >= 4 and !scene_states.first_warning:
			first_guard_warning()
		elif scene_states.first_warning and !scene_states.player_took_broom and !scene_states.guard_angry:
			if broom_timer:
				if broom_timer.is_stopped():
					broom_timer.start()
		elif $Trash.get_child_count() >= 10 and scene_states.first_warning and !scene_states.guard_angry:
			angry_guard()
			
func _on_player_exited_scene():
	if scene_states.locksmith_arrived:
		scene_states.player_left_ontime = true
		scene_finished.emit(scene_name, scene_states)
	elif !scene_states.player_in_pillory:
		scene_states.player_left_early = true
		player.process_mode = Node.PROCESS_MODE_DISABLED
		main_guard.move_to(player.global_position)
		await main_guard.target_reached
		player.process_mode = Node.PROCESS_MODE_INHERIT
		GameManager.init_dialogue(player, main_guard, "town_square_player_left_early")
		
func first_guard_warning():
	scene_states.first_warning = true
	main_guard.move_to(player.global_position)
	main_guard.say(tr("GUARD_LINE_2"), 4.0)
	
func angry_guard():
	if broom_timer: broom_timer.queue_free()
	scene_states.guard_angry = true
	main_guard.chase(player)
	await main_guard.target_reached
	if current_dialogue: current_dialogue.queue_free()
	GameManager.init_dialogue(player, main_guard, "town_square_angry_guard", true)
		
func _on_player_attacked(attack_obj, damage):
	if GameManager.game_state == GameManager.GameStates.BATTLE: return
	if attack_obj:
		attack_obj.hit(damage) #any character can be hit now
	if attack_obj is BasicCombatant:
		if attack_obj == main_guard and scene_states.locksmith_arrived:
			main_guard.get_node("Sprite3D/SubViewport/Sprite2D").texture.region.position.x = 0
		GameManager.init_battle(player, attack_obj)
	elif attack_obj == elf_girl:
		pass #TO DO: MAKE HER DISAPPEAR ALREADY
	elif attack_obj == old_man:
		angry_guard()
		
func init_dialogue(player_ref, speaker_ref, dialogue_name):
	var d = dialogue.instantiate()
	add_child(d)
	current_dialogue = d
	d.player_scene = player_ref
	d.speaker_scene = speaker_ref
	if dialogue_name == "time_to_go":
		var dic = {
			"char_name": {"ru":"Страж", "en": "Guard"},
			"events": { "0": { "text": { "ru": "Пора домой, червь", "en": "Time to go home, worm."}}}
		}
		d.init_dialogue_from_data(dialogue_name, dic)
	elif dialogue_name == "town_square_old_elf":
		d.init_dialogue_from_file(dialogue_name, {"tried": scene_states.tried_moving_chest})
	else:
		d.init_dialogue_from_file(dialogue_name)
	
func _on_dialogue_finished(dialogue_name, results):
	current_dialogue = null
	match dialogue_name:
		"town_square_elf_girl_ontime":
			scene_states.locksmith_dexterity = results.rolling_dexterity
			scene_states.locksmith_charisma = results.rolling_charisma
			if !results.rolling_dexterity and !results.rolling_charisma:
				pass #TO DO: MAKE HER DISAPPEAR ALREADY
		"town_square_player_left_early":
			if results.running:
				dice_contested.emit(self, ["town_square_player_running", CharStats.Stat.SPEED, 
				CharStats.Stat.SPEED, main_guard.stats.stats[CharStats.Stat.SPEED]])
			else:
				angry_guard()
		"town_square_old_elf":
			if results.doing_check:
				dice_check.emit(self, "town_square_old_elf_strength_check")
			else:
				old_man.say("OLD_ELF_COMPLAIN")
		"town_square_angry_guard":
			if results.submitted: send_player_to_pillory()
			elif results.running:
				dice_contested.emit(self, ["town_square_player_running", CharStats.Stat.SPEED, 
				CharStats.Stat.SPEED, main_guard.stats.stats[CharStats.Stat.SPEED]])
			elif scene_states.player_left_early:
				scene_states["player_left_early_and_started_battle"] = true
				scene_finished.emit(scene_name, scene_states)
			else:
				GameManager.init_battle(player, main_guard)
		"town_square_player_lost_fight":
			if results.submitted:
				scene_states["player_started_fight_and_submitted"] = true
				scene_finished.emit(scene_name, scene_states)
			else:
				main_guard.play_anim("attack")
				player.play_anim("die")
				await get_tree().create_timer(1.0).timeout
				scene_states["player_died"] = true
				scene_finished.emit(scene_name, scene_states)
		"time_to_go":
			scene_finished.emit(scene_name, scene_states)
			
func _on_battle_finished(player_ref, enemy_ref, has_player_won):
	#TO DO: ADD BATTLE ID OR SOMETHING
	#CURRENTLY IT'S ONLY PLAYER AND MAIN GUARD THAT ARE FIGHTING
	if !has_player_won:
		await get_tree().create_timer(2.0).timeout #as battle_handler returns battlers
		player.play_anim("struck")
		GameManager.init_dialogue(player_ref, enemy_ref, "town_square_player_lost_fight")
		#scene_states["player_died_in_battle"] = true
		#scene_finished.emit(scene_name, scene_states)
			
#dice_handler from main calls that
func _on_dice_rolled(roll_id, roll_result):
	match roll_id:
		"town_square_old_elf_strength_check":
			if roll_result:
				scene_states.moved_chest = true
				var fade = load("res://scenes/effects/fade_in_out.tscn").instantiate()
				add_child(fade)
				await fade.fade_in_finished
				$chest.queue_free()
				old_man.say(tr("OLD_ELF_THANKFUL"))
				await get_tree().create_timer(1).timeout
				old_man.move_to(Vector3(12.1,
				old_man.global_position.y, -7.9))
				await old_man.target_reached
				old_man.queue_free()
			else:
				scene_states.tried_moving_chest = true
			
func send_player_to_pillory():
	player.current_state = GameManager.CharStates.MOVING
	player.moving_point = $pillory.global_position
	main_guard.move_to($pillory.global_position)
	await main_guard.target_reached
	var p = $pillory.get_node("Sprite3D")
	p.play("default")
	await p.animation_finished
	scene_states.player_in_pillory = true
	player.hide()
	player.get_node("CollisionShape3D").disabled = true
	main_guard.move_to(Vector3(0, 0.7, 0))
	Engine.time_scale = 3
	
func manage_passers(delta):
	if !active_passers.is_empty():
		var paths_to_remove = []
		for p in active_passers:
			if p.inversed: 
				p.path.progress -= passer_by_speed * delta
				if p.path.progress_ratio <= 0: paths_to_remove.append(p)
				elif p.littering:
					if p.path.progress_ratio <= p.litter_moment:
						if p.path.get_children()[0].get_node("on_screen").is_on_screen():
							p.littering = false
							spawn_trash(p.path.get_children()[0].global_position)
			else: 
				p.path.progress += passer_by_speed * delta
				if p.path.progress_ratio >= 1: paths_to_remove.append(p)
				elif p.littering:
					if p.path.progress_ratio >= p.litter_moment:
						if p.path.get_children()[0].get_node("on_screen").is_on_screen():
							p.littering = false
							spawn_trash(p.path.get_children()[0].global_position)
		if !paths_to_remove.is_empty():
			for p in paths_to_remove:
				p.path.get_children()[0].queue_free()
				active_passers.erase(p)
	passer_by_timer -= delta
	if passer_by_timer <= 0:
		passer_by_timer = randf_range(2, 4)
		spawn_passer()
		
func spawn_trash(pos):
	var t = trash.instantiate()
	$Trash.add_child(t)
	t.global_position = Vector3(pos.x, t.global_position.y, pos.z)
		
func spawn_passer():
	var path = get_free_path() #pathfollow node
	if path:
		var passer
		if randi() % 2 == 0: passer = passer_by_male.instantiate()
		else: passer = passer_by_female.instantiate()
		path.add_child(passer)
		path.progress_ratio = randi() % 2
		var dic = {"path": path, 
		"inversed": path.progress_ratio == 1,
		"littering": randi() % 2 == 0}
		passer.flip_h = dic.inversed
		if dic.littering: dic["litter_moment"] = randf_range(0.1, 0.9)
		active_passers.append(dic)
		
func get_free_path():
	for p in $Paths.get_children():
		var follow = p.get_node("PathFollow3D")
		if follow.get_child_count() == 0:
			return follow
	return null

func _on_sun_down(_anim_name):
	if scene_states.player_in_pillory: Engine.time_scale = 1
	else:
		main_guard.chase(player)
		await main_guard.target_reached
	GameManager.init_dialogue(player, main_guard, "time_to_go")

func _on_locksmith_timer_timeout():
	$locksmith_timer.queue_free()
	locksmith = load("res://scenes/characters/basic_character.tscn").instantiate()
	locksmith.character_data = load("res://custom_resources/mr_locksmith.tres")
	add_child(locksmith)
	locksmith.interacted.connect(_on_locksmith_interacted)
	locksmith.global_position = $locksmith_spawn_position.global_position
	locksmith.move_to(main_guard.global_position)
	await locksmith.target_reached
	scene_states.locksmith_arrived = true
	if main_guard.current_state == GameManager.CharStates.BATTLE:
		locksmith.say(tr("LOCKSMITH_CONFUSED"))
	else:
		locksmith.say(tr("LOCKSMITH_HELLO"))
		main_guard.get_node("Sprite3D/SubViewport/Sprite2D").texture.region.position.x = 297
		if elf_girl.get_node("VisibleOnScreenNotifier3D").is_on_screen():
			elf_girl.say("Hey")
		else:
			await elf_girl.get_node("VisibleOnScreenNotifier3D").screen_entered
			elf_girl.say("Hey")
		
func _on_locksmith_interacted():
	if !scene_states.locksmith_dexterity and !scene_states.locksmith_charisma:
		locksmith.say(tr("WHAT"))
	elif scene_states.locksmith_dexterity:
		dice_contested.emit(self, ["town_square_locksmith_dexterity", CharStats.Stat.DEXTERITY, 
				CharStats.Stat.PERCEPTION, main_guard.stats.stats[CharStats.Stat.PERCEPTION]])
	elif scene_states.locksmith_charisma:
		dice_contested.emit(self, ["town_square_locksmith_charisma", CharStats.Stat.CHARISMA, 
				CharStats.Stat.PERCEPTION, main_guard.stats.stats[CharStats.Stat.PERCEPTION]])
