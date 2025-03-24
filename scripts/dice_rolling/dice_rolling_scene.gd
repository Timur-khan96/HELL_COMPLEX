extends Node3D

signal dice_roll_finished(value)

@onready var upper_circle = %upper_circle

var die_scene = load("res://scenes/dice_rolling/die.tscn")
var wild_explosion_scene = load("res://scenes/effects/wild_explosion.tscn")
var overall_value: int = 0
var dice_countdown

func _ready():
	upper_circle.texture.region.position.x = 0

func init_contested_roll(player_stat: CharStats.Stat, enemy_stat: CharStats.Stat, enemy_stat_bonus: int):
	set_dice(true)
	%main_label.text = tr("ENEMY_THROWS") + ": " + tr(CharStats.Stat.keys()[enemy_stat].to_upper())
	%main_label.text += " (+" + str(enemy_stat_bonus) + ")"
	await dice_roll_finished
	var enemy_result = overall_value + enemy_stat_bonus
	overall_value = 0
	free_dice()
	return await init_check_roll(player_stat, enemy_result)

func init_check_roll(stat: CharStats.Stat, difficulty: int = 6):
	set_dice(GameManager.auto_roll)
	%main_label.text = tr(CharStats.Stat.keys()[stat].to_upper())
	%main_label.text += " (+" + str(GameManager.player_stats.stats[stat]) + ")"
	%diff_label.text = str(difficulty)
	await dice_roll_finished
	overall_value += GameManager.player_stats.stats[stat]
	%result_label.text = str(overall_value)
	await get_tree().create_timer(2.0).timeout
	%diff_label.text = ""
	%result_label.text = ""
	var result: bool
	if overall_value >= difficulty:
		%main_label.text = tr("SUCCESS")
		%upper_circle.texture.region.position.x = 128
		result = true
	else:
		%upper_circle.texture.region.position.x = 256
		%main_label.text = tr("FAIL")
		result = false
	await get_tree().create_timer(2.0).timeout
	return result

func set_dice(auto_roll: bool = false, dice_count: int = 2, wild_dice_count: int = 1):
	dice_countdown = dice_count;
	var spacing = 0.5
	var die_size = Vector2(0.25,0.25)
	var total_width = (die_size.x * dice_count) + (spacing * (dice_count - 1))
	var start_x = -total_width / 2
	
	for i in range(dice_count):
		var dice_instance = die_scene.instantiate()
		if wild_dice_count > 0:
			dice_instance.is_wild_die = true
			wild_dice_count -= 1
		dice_instance.position = Vector3(start_x + i * (die_size.x + spacing), 0, 0)
		dice_instance.roll_finished.connect(_on_die_roll_finished)
		$dice.add_child(dice_instance)
		if auto_roll: dice_instance.roll()
			
func _on_die_roll_finished(value, die):
	overall_value += value
	if die.is_wild_die and value == 6:
		var explosion = wild_explosion_scene.instantiate()
		die.add_child(explosion)
		explosion.emitting = true
		%main_label.text = "WILD"
		die.roll()
	else:
		dice_countdown -= 1;
		if dice_countdown == 0:
			dice_roll_finished.emit()
			
func free_dice():
	for d in $dice.get_children():
		d.queue_free();
	
		
	
