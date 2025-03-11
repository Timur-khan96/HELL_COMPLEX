extends StaticBody3D

signal target_reached

var stats: CharacterStats
@export var obj_name = "Guard"
@export var level: int = 5
@export var is_combatant: bool = true

@onready var health_bar = %health_bar
@onready var speech = $speech
@onready var damage_pop = $damage_pop
@onready var anim = $AnimationPlayer
@onready var state_machine = $state_machine
@onready var nav_agent = $NavigationAgent3D

var health
var movement_speed

func _ready():
	stats = CharacterStats.new_random(level)
	health = stats.get_default_health()
	health_bar.max_value = health
	health_bar.value = health
	movement_speed = stats.get_movement_speed()
	
func _physics_process(delta):
	if state_machine.current_state == GameManager.CharStates.MOVING:
		if NavigationServer3D.map_get_iteration_id(nav_agent.get_navigation_map()) == 0:
			return
		if nav_agent.is_navigation_finished():
			target_reached.emit()
			state_machine.change_state(GameManager.CharStates.IDLE)
			stop_anim("move")
			return
		var next_point = nav_agent.get_next_path_position()
		var movement_delta = movement_speed * delta
		var velocity = global_position.direction_to(next_point) * movement_delta
		global_position = global_position.move_toward(global_position + velocity, movement_delta)
		play_anim("move")
		
func say(text: String, lifetime: float = 3.0):
	speech.text = text
	speech.show()
	await get_tree().create_timer(lifetime).timeout
	speech.hide()

func play_anim(anim_name):
	if anim.current_animation != anim_name:
		anim.play(anim_name)
func has_anim(anim_name): return anim.has_animation(anim_name)
func stop_anim(anim_name): 
	if anim.current_animation == anim_name:
		anim.stop()
		
func move_to(target): state_machine.move_to(target)
func chase(target): state_machine.chase(target)

func hit(damage):
	show_damage(damage)
	health_bar.show()
	var tween = get_tree().create_tween()
	tween.tween_property(health_bar, "value", health - damage, 1)
	tween.tween_interval(0.5)
	tween.tween_callback(health_bar.hide)
	await tween.finished
	health -= damage
	if health <= 0:
		health = 0;
		die()
	
func die():
	play_anim("die")
	remove_from_group("combatant")
	add_to_group("lootable")
	state_machine.change_state(GameManager.CharStates.DEAD)
	$CollisionShape3D.disabled = true
	
func show_damage(damage):
	damage_pop.show()
	damage_pop.text = "-" + str(int(damage))
	var pop_pos = damage_pop.global_position
	var tween = get_tree().create_tween()
	tween.tween_property(damage_pop, "global_position", Vector3.UP * 2, 2).as_relative()
	await tween.finished
	damage_pop.hide()
	damage_pop.global_position = pop_pos

func _on_interact_area_body_entered(body):
	if body is Player:
		body._interaction_entered(self)

func _on_interact_area_body_exited(body):
	if body is Player:
		body._interaction_exited(self)
