extends StaticBody3D
class_name BasicCharacter
#can be attacked and interacted with; no stats, don't die
signal interacted
signal target_reached
signal screen_entered
signal screen_exited

@export var obj_name: String = "NONAME"
@export var attack_reaction: String 
@export var movement_speed: float = 4.0
@export var texture: Texture2D: set = set_character_texture

		
var current_state: 
	get: return state_machine.current_state
	set(value):
		state_machine.current_state = value

@onready var speech = $speech
@onready var anim = $AnimationPlayer
@onready var state_machine = $state_machine
@onready var nav_agent = $NavigationAgent3D
@onready var interact_area = $interact_area
@onready var visible_on_screen_notifier_3d = $VisibleOnScreenNotifier3D


func set_character_texture(value):
	texture = value
	var sprite = get_node_or_null("Sprite3D")
	if sprite: sprite.texture = value

func _ready():
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	visible_on_screen_notifier_3d.screen_entered.connect(func():
		screen_entered.emit(self))
	visible_on_screen_notifier_3d.screen_exited.connect(func():
		screen_exited.emit(self))

func _physics_process(delta):
	if state_machine.current_state == GameManager.CharStates.MOVING:
		if NavigationServer3D.map_get_iteration_id(nav_agent.get_navigation_map()) == 0:
			return
		if nav_agent.is_navigation_finished():
			state_machine.change_state(GameManager.CharStates.IDLE)
			stop_anim("move")
			target_reached.emit()
			return
		var next_point = nav_agent.get_next_path_position()
		next_point.y = global_position.y
		var movement_delta = movement_speed * delta
		global_position = global_position.move_toward(next_point, movement_delta)
		play_anim("move")

func interact(_player_scene):
	interacted.emit(self)
	
func hit(_damage):
	say(tr(attack_reaction))
	
func say(text: String, lifetime: float = 3.0):
	speech.text = text
	speech.show()
	await get_tree().create_timer(lifetime).timeout
	speech.hide()
	
func move_to(target): state_machine.move_to(target)
func chase(target): state_machine.chase(target)
	
func play_anim(anim_name):
	if anim.current_animation != anim_name and has_anim(anim_name):
		anim.play(anim_name)
func has_anim(anim_name): return anim.has_animation(anim_name)
func stop_anim(anim_name): 
	if anim.current_animation == anim_name:
		anim.stop()

func _on_body_entered(body):
	if body is Player:
		body._interaction_entered(self)

func _on_body_exited(body):
	if body is Player:
		body._interaction_exited(self)
