extends RigidBody3D

signal roll_finished(value)

@onready var raycasts = $raycasts.get_children();
var roll_strength = 6;
var is_rolling: bool = false;
var is_wild_die: bool = false

func _ready():
	var d #mesh
	if is_wild_die:
		d = load("res://models/wild_die.glb").instantiate()
		add_child(d)
	else:
		d = load("res://models/regular_die.glb").instantiate()
		add_child(d)
	d.scale = Vector3(0.125, 0.125, 0.125)

func _process(_delta):
	if Input.is_anything_pressed() and !is_rolling: roll()

func roll():
	sleeping = false;
	freeze = false;
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	
	#random rotation
	transform.basis = Basis(Vector3.RIGHT, randf_range(0, 2*PI)) * transform.basis
	transform.basis = Basis(Vector3.UP, randf_range(0, 2*PI)) * transform.basis
	transform.basis = Basis(Vector3.FORWARD, randf_range(0, 2*PI)) * transform.basis
	
	#random throw impulse
	var throw_vector = Vector3(randf_range(-1,1), 0, randf_range(-1,1)).normalized()
	angular_velocity = throw_vector * roll_strength / 2
	apply_central_impulse(throw_vector * roll_strength)
	is_rolling = true;

func _on_sleeping_state_changed():
	if sleeping:
		var landed_on_side = false;
		for ray in raycasts:
			if ray.is_colliding():
				roll_finished.emit(ray.opposite_side, self);
				landed_on_side = true;
				break
				
		if !landed_on_side:
			roll();
