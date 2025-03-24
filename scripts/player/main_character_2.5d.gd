extends CharacterBody3D
class_name Player

signal attacked
signal dead

var current_state: GameManager.CharStates = GameManager.CharStates.IDLE:
	set(value):
		if current_state == value: return
		current_state = value
		if value != GameManager.CharStates.MOVING: stop_anim("move")
		if value == GameManager.CharStates.DIALOGUE: action_info.hide()
		elif value == GameManager.CharStates.BATTLE: action_info.hide()
		else: action_info.show()

@onready var anim_tree = $AnimationTree
@onready var equipped_1 = %sprite_skeleton.get_node("sprites/left_hand/equipped_1")
@onready var action_info = $MarginContainer/action_info
@onready var health_bar = %health_bar
@onready var damage_pop = $damage_pop
@onready var nav_agent = $NavigationAgent3D
@onready var speech = $speech
@onready var attack_timer = $attack_timer

var interactions = []
var equipped_item = null

var moving_point = null #to move with move_to func in BUSY state

var health: 
	get(): return GameManager.player_health
	set(value): GameManager.player_health = value
var movement_speed:
	get(): return GameManager.player_stats.get_movement_speed()
	
var stats = GameManager.player_stats
var battle_stats

func _ready():
	health_bar.max_value = GameManager.player_stats.get_default_health()
	health_bar.value = GameManager.player_health
	battle_stats = get_default_battlestats()
	GameManager.player_stats.skill_changed.connect(get_default_battlestats)

func _physics_process(_delta):
	if current_state == GameManager.CharStates.MOVING: #THIS STATE ONLY FOR AUTOMOVE
		if moving_point != null: move_to_moving_point()
		return
	if current_state != GameManager.CharStates.IDLE: return
	
	var input_dir = Input.get_vector("Left", "Right", "Up", "Down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * movement_speed
		velocity.z = direction.z * movement_speed
		$Sprite3D.flip_h = direction.x < 0
		anim_tree.play_anim("move")
	else:
		velocity.x = 0
		velocity.z = 0
		anim_tree.stop_anim("move")
		
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("pushing"):
			var push_direction = collision.get_normal().cross(Vector3.UP) * 2.0
			velocity += push_direction
	move_and_slide()

func get_equipped(): return equipped_1
#TO DO: ADD CHARACTER EQUIPMENT VALUES TO BATTLE STATS
func get_default_battlestats(): 
	return GameManager.player_stats.get_default_battlestats()

func get_armor(): return GameManager.player_stats.get_default_armor()

func say(text: String, lifetime: float = 3.0):
	if GameManager.game_state == GameManager.GameStates.BATTLE:
		speech.position.x = 0.5
	else:
		speech.position.x = 0
	speech.text = text
	speech.show()
	await get_tree().create_timer(lifetime).timeout
	speech.hide()

func move_to_moving_point():
	if moving_point == null: return
	if nav_agent.target_position != moving_point:
		nav_agent.target_position = moving_point
	if nav_agent.is_navigation_finished(): return
	velocity = global_position.direction_to(nav_agent.get_next_path_position()) * movement_speed
	move_and_slide()
	play_anim("move")
	if global_position.distance_to(moving_point) <= 1:
		moving_point = null
		stop_anim("move")
		#target_reached.emit()???

func play_anim(anim_name): anim_tree.play_anim(anim_name)
func stop_anim(anim_name): anim_tree.stop_anim(anim_name)
	
func _input(event):
	if current_state != GameManager.CharStates.IDLE: return
	if event.is_action_pressed("Fight"): attack()
	if event.is_action_pressed("Interact"): interact()
		
func interact():
	if !interactions.is_empty():
		interactions.back().interact(self)
		
func attack():
	var attack_object = null
	anim_tree.play_anim("attack")
	if GameManager.game_state == GameManager.GameStates.ADVENTURE:
		if !interactions.is_empty():
			for i in interactions:
				if i is BasicCharacter:
					#TO DO: ADD CHARACTER WEAPON TO THE ANIMATION FINISHED ATTACKED EMIT
					attack_object = i
	elif GameManager.game_state == GameManager.GameStates.BATTLE:
		attack_timer.start(battle_stats[GameManager.BattleStat.ATTACK_COOLDOWN])
		reset_battlestats_after_attack()
		
	await anim_tree.animation_finished
	var d = battle_stats[GameManager.BattleStat.DAMAGE]
	if randf() <= battle_stats[GameManager.BattleStat.CRIT_CHANCE]:
		d *= battle_stats[GameManager.BattleStat.CRIT_MULTI]
	attacked.emit(attack_object, d)
	if GameManager.game_state == GameManager.GameStates.BATTLE:
		reset_battlestats_after_attack()
			
func hit(damage):
	damage = max(damage - get_armor(), 0)
	show_damage(damage)
	if damage > 0:
		health_bar.show()
		var tween = get_tree().create_tween()
		tween.tween_property(health_bar, "value", health - damage, 1)
		tween.tween_interval(0.5)
		tween.tween_callback(health_bar.hide)
		await tween.finished
		
		health -= damage
		if health <= 0:
			health = 0;
			if GameManager.game_state != GameManager.GameStates.BATTLE:
				anim_tree.play_anim("die")
			else:
				dead.emit(self)
			
	if GameManager.game_state == GameManager.GameStates.BATTLE:
		battle_stats[GameManager.BattleStat.ARMOR] = get_armor()
		
func die(): play_anim("die")
	
func show_damage(damage):
	damage_pop.show()
	damage_pop.text = "-" + str(int(damage))
	var pop_pos = damage_pop.global_position
	var tween = get_tree().create_tween()
	tween.tween_property(damage_pop, "global_position", Vector3.UP * 2, 2).as_relative()
	await tween.finished
	damage_pop.hide()
	damage_pop.global_position = pop_pos
		
func set_action_info(interaction):
	action_info.text = interaction.obj_name
	if interaction is BasicCharacter:
		action_info.text += ", [F] to attack, [E] to interact"
	if interaction is Equipable:
		action_info.text += ", [E] to equip"
	if interaction is Interactable:
		action_info.text += ", [E] to interact"
	
func _interaction_entered(interaction):
	if !interactions.has(interaction): interactions.append(interaction)
	set_action_info(interaction)
	
func _interaction_exited(interaction):
	if interactions.has(interaction):
		interactions.erase(interaction)
		if interactions.is_empty():
			action_info.text = ""
		else:
			set_action_info(interactions.back())
			
func equip(item: Item):
	equipped_item = item
	equipped_1.texture = item.texture
	equipped_1.position = item.sprite_transform.position
	equipped_1.rotation_degrees = item.sprite_transform.rotation
	equipped_1.scale = item.sprite_transform.scale
	
func reset_battlestats_after_attack(): 
	var default_stats = get_default_battlestats()
	battle_stats[GameManager.BattleStat.DAMAGE] = default_stats[GameManager.BattleStat.DAMAGE]
	battle_stats[GameManager.BattleStat.CRIT_CHANCE] = default_stats[GameManager.BattleStat.CRIT_CHANCE]
	battle_stats[GameManager.BattleStat.CRIT_MULTI] = default_stats[GameManager.BattleStat.CRIT_MULTI]
	
func _on_attack_timer_timeout():
	if GameManager.game_state == GameManager.GameStates.BATTLE:
		attack()
	else: $attack_timer.stop()
	
func update_attack_timer(value: float):
	var new_time = attack_timer.time_left - value
	if new_time <= 0: attack_timer.timeout.emit()
	else: attack_timer.start(new_time)
	
