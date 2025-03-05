extends Resource
class_name CharacterStats

@export var strength: int = 1
@export var dexterity: int = 1
@export var intelligence: int = 1
@export var endurance: int = 1
@export var charisma: int = 1
@export var luck: int = 1

func get_default_battle_stats() -> Dictionary:
	var battle_stats = {}
	battle_stats["armor"] = dexterity
	battle_stats["damage"] = 2 + (strength * 2)
	battle_stats["mana"] = 10 + intelligence * 2
	battle_stats["attack_cooldown"] = max(12.0 - (dexterity * 0.2), 2.0)
	battle_stats["crit_chance"] = clamp(0.05 + (luck * 0.01), 0.01, 0.95)
	battle_stats["crit_multi"] = 1.5 
	return battle_stats
	
func get_default_health():
	return 50 + (endurance * 10)

func reset_after_attack(battle_stats: Dictionary) -> void:
	var default_stats = get_default_battle_stats()
	battle_stats.damage = default_stats.damage
	battle_stats.attack_cooldown = default_stats.attack_cooldown
	battle_stats.crit_chance = default_stats.crit_chance
	battle_stats.crit_multi = default_stats.crit_multi

func reset_after_hit(battle_stats: Dictionary) -> void:
	battle_stats.armor = dexterity
