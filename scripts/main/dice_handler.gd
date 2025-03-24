extends Node

var dice_rolling_scene = load("res://scenes/dice_rolling/dice_rolling_scene.tscn")
var roll_difficulties = {
	"town_square_old_elf_strength_check": [6, CharStats.Stat.STRENGTH]
	}
var initial_camera = null

func init_dice_check(parent_scene, roll_id):
	var dice_rolling_node = set_scene(parent_scene)
	var stat: CharStats.Stat = CharStats.Stat.STRENGTH
	var difficulty: int = 6
	
	if roll_difficulties.has(roll_id):
		difficulty = roll_difficulties[roll_id][0]
		stat = roll_difficulties[roll_id][1]
	else:
		print("Roll id doesn't match anything in dice handler")
			
	var roll_result = await dice_rolling_node.init_check_roll(stat, difficulty)
	
	finish(parent_scene, dice_rolling_node, roll_id, roll_result)
	
func init_dice_contested(parent_scene, roll_data):
	var dice_rolling_node = set_scene(parent_scene)
	var roll_result = await dice_rolling_node.init_contested_roll(roll_data[1], roll_data[2], roll_data[3])
	finish(parent_scene, dice_rolling_node, roll_data[0], roll_result)
	
func set_scene(parent_scene):
	var s = dice_rolling_scene.instantiate()
	parent_scene.add_child(s)
	initial_camera = parent_scene.get_node_or_null("Camera3D")
	var player: Player = parent_scene.get_node_or_null("player")
	if player and player.get_node("VisibleOnScreenNotifier3D").is_on_screen():
		s.global_position = player.global_position
		s.global_position.z += 1
	else: set_on_screen_center(s, initial_camera)
	s.global_position.y = 0.3
	s.get_node("Camera3D").make_current()
	parent_scene.process_mode = PROCESS_MODE_DISABLED
	for c in s.get_node("walls").get_children():
		c.disabled = false
	return s
	
func set_on_screen_center(dice_scene, cam):
	if cam == null: return
	var screen_size = get_viewport().size
	var center = Vector2(screen_size.x / 2, screen_size.y / 2)
	var space_state = dice_scene.get_world_3d().direct_space_state
	var origin = cam.project_ray_origin(center)
	var end = origin + cam.project_ray_normal(center) * 1000
	var query = PhysicsRayQueryParameters3D.create(origin, end, 2)
	var result = space_state.intersect_ray(query)
	if result and result.collider:
		dice_scene.global_position = result.position
		
func finish(parent_scene, dice_rolling_node, roll_id, roll_result):
	parent_scene.process_mode = PROCESS_MODE_INHERIT
	if initial_camera: initial_camera.make_current()
	dice_rolling_node.queue_free()
	parent_scene._on_dice_rolled(roll_id, roll_result)
