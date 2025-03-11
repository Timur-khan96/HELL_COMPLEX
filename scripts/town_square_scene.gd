extends Node3D

@onready var camera = $Camera3D
@onready var main_guard = $guard

var passer_by_male = load("res://scenes/passer_by.tscn")
var passer_by_female = load("res://scenes/passer_by_woman.tscn")
var trash = load("res://scenes/interactable/trash.tscn")
var passer_by_timer
var passer_by_speed = 2.0

var active_passers = []
var scene_states = {
	"first_warning": false,
	"guard_angry": false
	}

func get_player_scene(): return $player

func _ready():
	passer_by_timer = randf_range(3, 6)
	camera.bound_camera(Vector2(5, 5), Vector2(-5, -5))
	main_guard.say("Take the broom and sweep the trash!", 5.0)

func _process(delta):
	manage_passers(delta)
	if $Trash.get_child_count() >= 4 and !scene_states.first_warning:
		scene_states.first_warning = true
		main_guard.move_to($player.global_position)
		await main_guard.target_reached
		print("Reached the player but not really because his path is not updated")
		#main_guard.say("Don't make me angry!")
	#elif $Trash.get_child_count() >= 10 and scene_states.first_warning and !scene_states.guard_angry:
		#scene_states.guard_angry = true
		#main_guard.move_to($player.global_position)
		#await main_guard.target_reached
		#print("Reached the player but not really because his path is not updated")
		
	
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
		passer_by_timer = randf_range(3, 6)
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
		"littering": randi() % 4 == 0}
		passer.flip_h = dic.inversed
		if dic.littering: dic["litter_moment"] = randf_range(0.1, 0.9)
		active_passers.append(dic)
		
func get_free_path():
	for p in $Paths.get_children():
		var follow = p.get_node("PathFollow3D")
		if follow.get_child_count() == 0:
			return follow
	return null
