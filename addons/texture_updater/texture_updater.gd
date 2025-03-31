@tool
extends EditorPlugin

func _enter_tree(): print("Texture Updater Plugin Enabled")

func _exit_tree(): print("Texture Updater Plugin Disabled")
	
func _process(_delta):
	var scene_root = get_tree().edited_scene_root
	if scene_root:
		_apply_textures(scene_root)
		
func _apply_textures(node):
	if node is BasicCharacter and node.character_data and node.character_data.texture:
		var sprite
		if node is BasicCombatant:
			sprite = node.get_node_or_null("Sprite3D/SubViewport/Sprite2D")
		else:
			sprite = node.get_node_or_null("Sprite3D")
			
		if sprite and sprite.texture != node.character_data.texture:
			sprite.texture = node.character_data.texture
			print("Updated texture for:", node.name)
	elif node is Equipable and node.resource:
		var sprite = node.get_node_or_null("Sprite3D")
		if sprite and sprite.texture != node.resource.texture:
			sprite.texture = node.resource.texture
			print("Updated texture for:", node.name)

	for child in node.get_children():
		_apply_textures(child)
