extends BasicCharacter
class_name BasicCombatant
#can die or attack
signal attacked
signal dead

@onready var health_bar = %health_bar
@onready var damage_pop = $damage_pop
@onready var attack_timer = $attack_timer
@onready var animation_player = $AnimationPlayer

@export var level: int = 5
@export var player_battle_threat: String #reaction to battle init from player
var stats: CharStats
var battle_stats
var health

func set_character_texture(value):
	texture = value
	var sprite = get_node_or_null("Sprite3D/SubViewport/Sprite2D")
	if sprite: sprite.texture = value

func _ready():
	super._ready()
	animation_player.animation_finished.connect(_on_animation_finished)
	stats = CharStats.new_random(level)
	battle_stats = get_default_battlestats()
	stats.skill_changed.connect(get_default_battlestats)
	health = stats.get_default_health()
	health_bar.max_value = health
	health_bar.value = health
	movement_speed = stats.get_movement_speed()
	
func attack(): 
	play_anim("attack")
	if GameManager.game_state == GameManager.GameStates.BATTLE:
		attack_timer.start(battle_stats[GameManager.BattleStat.ATTACK_COOLDOWN])
		reset_battlestats_after_attack() #this one is not necessary right now
					
func _on_animation_finished(anim_name):
	if anim_name == "attack":
		var d = battle_stats[GameManager.BattleStat.DAMAGE]
		if randf() <= battle_stats[GameManager.BattleStat.CRIT_CHANCE]:
			d *= battle_stats[GameManager.BattleStat.CRIT_MULTI]
			say("Scared already?")
		attacked.emit(null, d) #attacking only player right now
	if anim_name == "die": queue_free()
			
func hit(damage):
	damage = max(damage - get_armor(), 0)
	show_damage(damage)
	if damage > 0:
		health_bar.show()
		var tween = get_tree().create_tween()
		tween.tween_property(health_bar, "value", health - damage, 1)
		tween.tween_interval(0.5)
		tween.tween_callback(health_bar.hide)
		await tween.finished
		
		health -= damage
		if health <= 0:
			health = 0;
			if GameManager.game_state != GameManager.GameStates.BATTLE:
				die() #in case death blow is outside of the battle
			else:
				dead.emit(self)
	if GameManager.game_state == GameManager.GameStates.BATTLE:
		battle_stats[GameManager.BattleStat.ARMOR] = get_armor()
			
func get_default_battlestats(): return stats.get_default_battlestats()
func get_armor(): return stats.get_default_armor()
	
func die():
	play_anim("die")
	state_machine.change_state(GameManager.CharStates.DEAD)
	$CollisionShape3D.disabled = true
	
func show_damage(damage):
	damage_pop.show()
	damage_pop.text = "-" + str(int(damage))
	var pop_pos = damage_pop.position
	var tween = get_tree().create_tween()
	tween.tween_property(damage_pop, "position", Vector3.UP * 2, 2).as_relative()
	await tween.finished
	damage_pop.hide()
	damage_pop.position = pop_pos
	
func say(text: String, lifetime: float = 3.0):
	if GameManager.game_state == GameManager.GameStates.BATTLE:
		speech.position.x = -0.8
	else:
		speech.position.x = 0
	super.say(text, lifetime)
	
#IN BATTLE, BUT WILL BASIC COMBATANT HAVE BONUSES??	
func reset_battlestats_after_attack(): 
	var default_stats = get_default_battlestats()
	battle_stats[GameManager.BattleStat.DAMAGE] = default_stats[GameManager.BattleStat.DAMAGE]
	battle_stats[GameManager.BattleStat.ATTACK_COOLDOWN] = default_stats[GameManager.BattleStat.ATTACK_COOLDOWN]
	battle_stats[GameManager.BattleStat.CRIT_CHANCE] = default_stats[GameManager.BattleStat.CRIT_CHANCE]
	battle_stats[GameManager.BattleStat.CRIT_MULTI] = default_stats[GameManager.BattleStat.CRIT_MULTI]

func _on_attack_timer_timeout():
	if GameManager.game_state == GameManager.GameStates.BATTLE:
		attack()
	else: $attack_timer.stop()
