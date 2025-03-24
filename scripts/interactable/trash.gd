extends DelayedInteractable

@onready var sprite_1 = $Sprite3D
@onready var sprite_2 = $Sprite3D2
@onready var collision_shape = $CollisionShape3D

func _ready():
	obj_name = "Trash"
	sprite_1.texture.region.position.x = (randi() % 4) * 64
	sprite_2.texture.region.position.x = (randi() % 4) * 64
	
	sprite_1.rotation.z = randf_range(0, TAU)
	sprite_2.rotation.z = randf_range(0, TAU)
	
	var extents = collision_shape.shape.size * 0.5
	sprite_2.global_position.x = collision_shape.global_position.x 
	sprite_2.global_position.x += randf_range(-extents.x, extents.x)
	sprite_2.global_position.z = collision_shape.global_position.z 
	sprite_2.global_position.z += randf_range(-extents.z, extents.z)

func interact(player_scene):
	if player_scene.equipped_item == null:
		player_scene.say(tr("TRASH_NO_BROOM"), 2.0)
		return
	if player_scene.equipped_item.obj_name == "broom":
		is_interacting = true
		player_scene.play_anim("sweep")
		while !player_scene.anim_tree["parameters/sweep_anim/active"]: 
			await get_tree().process_frame 
		while player_scene.anim_tree["parameters/sweep_anim/active"]:
			await get_tree().process_frame
			if !is_interacting:
				player_scene.stop_anim("sweep")
				return
		super.complete_interaction()
	else:
		player_scene.say(tr("TRASH_NO_BROOM_2"), 2.0)
