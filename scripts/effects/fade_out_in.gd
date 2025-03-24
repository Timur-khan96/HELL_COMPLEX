extends ColorRect

signal fade_in_finished

func _ready():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "color:a", 1, 0.5)
	tween.finished.connect(func():
		fade_in_finished.emit()
		var new_tween = get_tree().create_tween()
		new_tween.tween_property(self, "color:a", 0, 0.5)
		new_tween.finished.connect(queue_free)
	)
