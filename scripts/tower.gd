class_name Tower
extends StaticBody2D

signal destroyed

var owner_player: int   = 0
var is_king_tower: bool = false
var max_hp: int         = 1400
var hp: int             = 0
var is_alive: bool      = true

var _attack_timer: float = 0.0
const ATTACK_DAMAGE: int   = 40
const ATTACK_RANGE: float  = 200.0
const ATTACK_SPEED: float  = 0.8   # attacks per second

func _ready() -> void:
	hp = max_hp
	add_to_group("towers")

func _process(delta: float) -> void:
	if not is_alive:
		return
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_try_attack()

func _try_attack() -> void:
	var enemy_team := 1 - owner_player
	var nearest: Node2D = null
	var nearest_dist := ATTACK_RANGE

	for node in get_tree().get_nodes_in_group("troops"):
		if node.get("owner_player") != enemy_team:
			continue
		if not node.get("is_alive"):
			continue
		var d := position.distance_to(node.position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = node

	if nearest:
		nearest.call("take_damage", ATTACK_DAMAGE)
		_attack_timer = 1.0 / ATTACK_SPEED

func take_damage(amount: int) -> void:
	if not is_alive:
		return
	hp = max(0, hp - amount)
	if hp == 0:
		_die()

func _die() -> void:
	is_alive = false
	modulate = Color(0.3, 0.3, 0.3, 0.7)
	remove_from_group("towers")
	destroyed.emit()
