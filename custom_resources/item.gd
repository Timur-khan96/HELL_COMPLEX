extends Resource
class_name Item

@export var obj_name: String #both for label and the inventory
@export var texture: Texture2D
@export var collision_arr: PackedVector2Array #for 2d mouse collision

@export var sprite_transform: Dictionary = {
	"position": Vector2(-78.6, 18.7),
	"rotation": 57.2,
	"scale": Vector2(2,2)
}
