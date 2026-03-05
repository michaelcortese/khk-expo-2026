class_name CardData
extends Resource

enum TroopType { KNIGHT, ARCHER, GIANT, BARBARIAN }

@export var card_id: String = ""
@export var display_name: String = "Card"
@export var cost: int = 3
@export var icon: Texture2D = null
@export var troop_type: TroopType = TroopType.KNIGHT

@export var max_hp: int = 200
@export var attack_damage: int = 30
@export var attack_range: float = 55.0
@export var attack_speed: float = 1.0   # attacks per second
@export var move_speed: float = 80.0
@export var targets_structures_only: bool = false
