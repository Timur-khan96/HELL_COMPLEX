extends Resource
class_name CharStats

signal skill_changed

enum Stat {
	STRENGTH, DEXTERITY, INTELLIGENCE, ENDURANCE,
	CHARISMA, LUCK, PERCEPTION, SPEED
}

@export var strength_damage_multiplier:float = 2.5
@export var dexterity_to_armor_divider:int = 2
@export var health_before_endurance:int = 50
const movement_before_speed = 3.0

@export var stats: Dictionary = {
	Stat.STRENGTH: 1, Stat.DEXTERITY: 1, Stat.INTELLIGENCE: 1,
	Stat.ENDURANCE: 1, Stat.CHARISMA: 1, Stat.LUCK: 1,
	Stat.PERCEPTION: 1, Stat.SPEED: 1
}

static func new_random(level: int = 5) -> CharStats:
	var result = CharStats.new()
	var stat_keys = result.stats.keys()
	for _i in range(level + 4):
		var key = stat_keys.pick_random()
		result.stats[key] = result.stats.get(key, 0) + 1
	return result
	
static func get_stat_enum_value(skill: String) -> int:
	var stat_map = {
		"strength": Stat.STRENGTH,
		"dexterity": Stat.DEXTERITY,
		"intelligence": Stat.INTELLIGENCE,
		"endurance": Stat.ENDURANCE,
		"charisma": Stat.CHARISMA,
		"luck": Stat.LUCK,
		"perception": Stat.PERCEPTION,
		"speed": Stat.SPEED
	}
	return stat_map.get(skill.to_lower(), -1)  # Return -1 if not found
	
func _to_string() -> String:
	var text := ""
	for stat in stats.keys():
		text += tr(Stat.keys()[stat].to_upper()) + ": " + str(stats[stat]) + "\n"
	return text.rstrip("\n")
	
func get_default_battlestats() -> Dictionary:
	return {
		GameManager.BattleStat.ARMOR: get_default_armor(),
		GameManager.BattleStat.DAMAGE: get_default_damage(),
		GameManager.BattleStat.MANA: 10 + stats[Stat.INTELLIGENCE] * 2,
		GameManager.BattleStat.ATTACK_COOLDOWN: max(12.0 - (stats[Stat.SPEED] * 0.2), 2.0),
		GameManager.BattleStat.CRIT_CHANCE: clamp(0.05 + (stats[Stat.LUCK] * 0.01), 0.01, 0.95),
		GameManager.BattleStat.CRIT_MULTI: 1.5 + (stats[Stat.PERCEPTION] * 0.2)
	}

func get_movement_speed(): return movement_before_speed + (0.2 * stats[Stat.SPEED])
	
func get_default_health():
	return health_before_endurance + (stats[Stat.ENDURANCE] * 10)
	
func get_default_damage():
	return 2 + (stats[Stat.STRENGTH] * strength_damage_multiplier)
	
func get_default_armor(): return stats[Stat.DEXTERITY] / dexterity_to_armor_divider
