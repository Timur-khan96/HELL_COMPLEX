extends CharacterBody3D
class_name Player

@onready var anim_tree = $AnimationTree
@onready var equipped_1 = %sprite_skeleton.get_node("sprites/left_hand/equipped_1")
@onready var action_info = $MarginContainer/action_info
@onready var health_bar = %health_bar
@onready var damage_pop = $damage_pop

var interactions = []
var current_enemy = null
var equipped_item = null

func get_equipped(): return equipped_1

func play_anim(anim_name): anim_tree.play_anim(anim_name)
func stop_anim(anim_name): anim_tree.stop_anim(anim_name)

var health: 
	get(): return GameManager.player_health
	
var movement_speed:
	get(): return GameManager.player_stats.get_movement_speed()
	
func _ready():
	health_bar.max_value = GameManager.player_stats.get_default_health()
	health_bar.value = GameManager.player_health

func _physics_process(_delta):
	if GameManager.game_state == GameManager.GameStates.BATTLE: return
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
	move_and_slide()
	
func _input(event):
	if GameManager.game_state == GameManager.GameStates.BATTLE: return
	if event.is_action_pressed("Fight"):
		anim_tree.play_anim("attack")
		var attackable = get_attackable()
		if attackable:
			current_enemy = attackable
	if event.is_action_pressed("Interact") and !interactions.is_empty():
		interactions.back().interact(self)
			
func get_attackable():
	if !interactions.is_empty():
		for i in interactions:
			if i.is_in_group("combatant"): return i #or Character
	return null
			
func hit(damage):
	show_damage(damage)
	GameManager.player_health -= damage
	if GameManager.player_health <= 0:
		anim_tree.play_anim("die")
	health_bar.show()
	var tween = get_tree().create_tween()
	tween.tween_property(health_bar, "value", GameManager.player_health, 1)
	tween.tween_interval(0.5)
	tween.tween_callback(health_bar.hide)
	
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
	if interaction.is_in_group("combatant"):
		action_info.text += ", [F] to fight."
	elif interaction is Equipable:
		action_info.text += ", [E] to equip"
	elif interaction is Interactable:
		action_info.text += ", [E] to interact"

func _on_animation_finished(anim_name):
	if anim_name == "attack" and current_enemy:
		if GameManager.game_state != GameManager.GameStates.BATTLE:
			$Sprite3D.flip_h = false
			GameManager.init_battle(self, current_enemy)
			current_enemy = null
			
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
			
func _on_battle_finished():
	anim_tree.stop_anim("fight_begin")
			
func equip(item: Item):
	equipped_item = item
	equipped_1.texture = item.texture
	equipped_1.position = item.sprite_transform.position
	equipped_1.rotation_degrees = item.sprite_transform.rotation
	equipped_1.scale = item.sprite_transform.scale
	
