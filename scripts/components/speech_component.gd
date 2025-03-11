extends Node

var speech_bubble = load("res://scenes/speech_bubble.tscn")

func say(text: String, time: float = 3.0):
	var bubble = speech_bubble.instantiate()
	get_parent().add_child(bubble)
	#bubble.global_position.x += 5
	bubble.global_position.y += 1
	bubble.get_node("%Label").text = text
	await get_tree().create_timer(time).timeout
	bubble.queue_free()
	
