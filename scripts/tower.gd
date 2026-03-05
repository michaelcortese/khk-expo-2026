class_name Tower
extends StaticBody2D

signal destroyed(tower: Tower)

@export var max_hp: int = 1400
@export var attack_damage: int = 40
@export var attack_range: float = 200.0
@export var attack_speed: float = 0.8   # attacks per second

var owner_player: int = 0   # 0 = P1 (left), 1 = P2 (right)
var is_king_tower: bool = false
var hp: int = 0
var is_alive: bool = true

var _attack_timer: float = 0.0
var _health_bar_fill: Line2D

const BAR_HALF: float = 45.0
const BAR_Y: float = -55.0

func _ready() -> void:
	hp = max_hp
	_build_health_bar()

func _build_health_bar() -> void:
	var hb_bg := Line2D.new()
	hb_bg.width = 8.0
	hb_bg.default_color = Color(0.15, 0.15, 0.15, 0.9)
	hb_bg.add_point(Vector2(-BAR_HALF, BAR_Y))
	hb_bg.add_point(Vector2(BAR_HALF, BAR_Y))
	add_child(hb_bg)

	_health_bar_fill = Line2D.new()
	_health_bar_fill.width = 8.0
	_health_bar_fill.default_color = Color(0.1, 0.85, 0.1)
	_health_bar_fill.add_point(Vector2(-BAR_HALF, BAR_Y))
	_health_bar_fill.add_point(Vector2(BAR_HALF, BAR_Y))
	add_child(_health_bar_fill)

func _process(delta: float) -> void:
	if not is_alive:
		return
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_try_attack()

func _try_attack() -> void:
	var enemy_team := 1 - owner_player
	var nearest: TroopUnit = null
	var nearest_dist := attack_range + 1.0

	for node in get_tree().get_nodes_in_group("troops"):
		var t := node as TroopUnit
		if t == null or not t.is_alive or t.owner_player != enemy_team:
			continue
		var d := position.distance_to(t.position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = t

	if nearest:
		nearest.take_damage(attack_damage)
		_attack_timer = 1.0 / attack_speed

func take_damage(amount: int) -> void:
	if not is_alive:
		return
	hp = max(0, hp - amount)
	if _health_bar_fill:
		var pct := float(hp) / float(max_hp)
		_health_bar_fill.set_point_position(1, Vector2(-BAR_HALF + BAR_HALF * 2.0 * pct, BAR_Y))
	if hp == 0:
		_die()

func _die() -> void:
	is_alive = false
	modulate = Color(0.25, 0.25, 0.25, 0.8)
	destroyed.emit(self)
