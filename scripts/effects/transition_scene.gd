extends ColorRect

signal transition_midway
signal transition_finished

@export var transition_duration := 2.0
var elapsed_time = 0.0
var pixel_size := 1.0
var increasing := true
var scene_swapped := false

func _ready():
	self.size = get_viewport_rect().size #THIS IS NECESSARY
	hide()
	await get_tree().process_frame 
	var img = get_viewport().get_texture().get_image()
	var tex = ImageTexture.create_from_image(img)
	self.material.set_shader_parameter("scene_texture", tex)
	show()
	transition()

func _process(delta):
	elapsed_time += delta
	var t = elapsed_time / (transition_duration / 2) 
	t = clamp(t, 0.0, 1.0)
	pixel_size = lerp(1.0, 50.0, t if increasing else 1.0 - t)
	if increasing and elapsed_time >= transition_duration / 2:
		increasing = false
		transition_midway.emit() 
		await get_tree().process_frame 
		
		var img = get_viewport().get_texture().get_image()
		var tex = ImageTexture.create_from_image(img)
		self.material.set_shader_parameter("new_scene_texture", tex)
		self.material.set_shader_parameter("use_new_scene", true) 
		scene_swapped = true
		
	if elapsed_time >= transition_duration:
		transition_finished.emit()
		queue_free()

	self.material.set_shader_parameter("pixel_size", pixel_size)

func transition():
	self.material.set_shader_parameter("pixelating", true)
