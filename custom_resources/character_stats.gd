extends Resource
class_name CharacterStats

@export var stats = {
	"strength": 1,
	"dexterity": 1,
	"intelligence": 1,
	"endurance": 1,
	"charisma": 1,
	"luck": 1,
	"perception": 1,
	"speed": 1
}

static func new_random(level: int = 5):
	var result = new()
	for _i in range(level + 4):
		result.stats[result.stats.keys().pick_random()] += 1
	return result

func _to_string():
	var t = tr("STRENGTH") + ": " + str(stats.strength) + "\n"
	t += tr("DEXTERITY") + ": " + str(stats.dexterity) + "\n"
	t += tr("INTELLIGENCE") + ": " + str(stats.intelligence) + "\n"
	t += tr("ENDURANCE") + ": " + str(stats.endurance) + "\n"
	t += tr("CHARISMA") + ": " + str(stats.charisma) + "\n"
	t += tr("LUCK") + ": " + str(stats.luck) + "\n"
	t += tr("PERCEPTION") + ": " + str(stats.perception) + "\n"
	t += tr("SPEED") + ": " + str(stats.speed)
	return t
	

func get_default_battle_stats() -> Dictionary:
	var battle_stats = {}
	battle_stats["armor"] = stats.dexterity
	battle_stats["damage"] = 2 + (stats.strength * 2)
	battle_stats["mana"] = 10 + stats.intelligence * 2
	battle_stats["attack_cooldown"] = max(12.0 - (stats.speed * 0.2), 2.0)
	battle_stats["crit_chance"] = clamp(0.05 + (stats.luck * 0.01), 0.01, 0.95)
	battle_stats["crit_multi"] = 1.5 + (stats.perception * 0.2)
	return battle_stats
	
func get_movement_speed(): return 3.0 + stats.speed
	
func get_default_health():
	return 50 + (stats.endurance * 25)

func reset_after_attack(battle_stats: Dictionary) -> void:
	var default_stats = get_default_battle_stats()
	battle_stats.damage = default_stats.damage
	battle_stats.attack_cooldown = default_stats.attack_cooldown
	battle_stats.crit_chance = default_stats.crit_chance
	battle_stats.crit_multi = default_stats.crit_multi

func reset_after_hit(battle_stats: Dictionary) -> void:
	battle_stats.armor = stats.dexterity
