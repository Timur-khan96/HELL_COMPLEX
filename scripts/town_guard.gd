extends StaticBody3D
class_name Attackable

@export var stats: CharacterStats

@onready var health_bar = %health_bar

var obj_name = "Guard lvl 5" #for player info
var health

func _ready():
	health = stats.get_default_health()
	health_bar.max_value = health
	health_bar.value = health

func play_anim(anim_name): $AnimationPlayer.play(anim_name)
func has_anim(anim_name): return $AnimationPlayer.has_animation(anim_name)
func stop_anim(anim_name): 
	if $AnimationPlayer.current_animation == anim_name:
		$AnimationPlayer.stop()

func hit(damage):
	health -= damage
	if health <= 0:
		health = 0;
		play_anim("die")
	health_bar.show()
	var tween = get_tree().create_tween()
	tween.tween_property(health_bar, "value", health, 1)
	tween.tween_interval(0.5)
	tween.tween_callback(health_bar.hide)

func _on_guard_interact_area_body_entered(body):
	if body is Player:
		body._interaction_entered(self)

func _on_guard_interact_area_body_exited(body):
	if body is Player:
		body._interaction_exited(self)
