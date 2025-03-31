extends CharacterData
class_name CombatantData

@export var level: int = 5
@export var player_battle_threat: String #reaction to battle init with this combatant from player
@export var stats: CharStats
@export var is_swapping: bool = false #determines if this combatant can swap stones in match 3 grid
