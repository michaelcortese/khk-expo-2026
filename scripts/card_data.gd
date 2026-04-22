class_name CardData
extends Resource

var card_id: String               = ""
var display_name: String          = "Card"
var cost: int                     = 3
var max_hp: int                   = 200
var attack_damage: int            = 30
var attack_range: float           = 55.0
var attack_speed: float           = 1.0
var move_speed: float             = 80.0
var targets_structures_only: bool = false
var is_ranged: bool               = false
var is_splash: bool               = false
var splash_radius: float          = 0.0
var troop_count: int              = 1     # how many troops this card spawns
var secondary_card: Resource      = null  # optional CardData for mixed-type spawns (e.g. Goblin Gang)
var secondary_count: int          = 0     # number of secondary troops to spawn
