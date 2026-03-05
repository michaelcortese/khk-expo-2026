class_name TroopUnit
extends CharacterBody2D

var owner_player: int = 0   # 0 = P1 (left), 1 = P2 (right)
var max_hp: int = 200
var hp: int = 0
var attack_damage: int = 30
var attack_range: float = 55.0
var attack_speed: float = 1.0   # attacks per second
var move_speed: float = 80.0
var targets_structures_only: bool = false
var is_alive: bool = true

var _attack_timer: float = 0.0
var _target: Node2D = null
var _enemy_king_pos: Vector2 = Vector2.ZERO
var _health_bar_fill: Line2D   # updated to reflect current HP

const BAR_HALF: float = 14.0
const BAR_Y: float = -24.0

## Called by GameManager right after instantiate(), before adding to scene tree.
func init(data: CardData, player_idx: int, enemy_king_position: Vector2) -> void:
	owner_player = player_idx
	max_hp = data.max_hp
	hp = max_hp
	attack_damage = data.attack_damage
	attack_range = data.attack_range
	attack_speed = data.attack_speed
	move_speed = data.move_speed
	targets_structures_only = data.targets_structures_only
	_enemy_king_pos = enemy_king_position
	add_to_group("troops")

func _ready() -> void:
	_build_visuals()

func _build_visuals() -> void:
	# Body square (Polygon2D = Node2D, respects camera)
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-13, -13), Vector2(13, -13),
		Vector2(13, 13), Vector2(-13, 13)
	])
	body.color = Color(0.2, 0.5, 1.0) if owner_player == 0 else Color(1.0, 0.3, 0.2)
	add_child(body)

	# Health bar background
	var hb_bg := Line2D.new()
	hb_bg.width = 5.0
	hb_bg.default_color = Color(0.15, 0.15, 0.15, 0.85)
	hb_bg.add_point(Vector2(-BAR_HALF, BAR_Y))
	hb_bg.add_point(Vector2(BAR_HALF, BAR_Y))
	add_child(hb_bg)

	# Health bar fill (green, shrinks left-to-right as HP drops)
	_health_bar_fill = Line2D.new()
	_health_bar_fill.width = 5.0
	_health_bar_fill.default_color = Color(0.1, 0.9, 0.1)
	_health_bar_fill.add_point(Vector2(-BAR_HALF, BAR_Y))
	_health_bar_fill.add_point(Vector2(BAR_HALF, BAR_Y))
	add_child(_health_bar_fill)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	_attack_timer -= delta
	_find_target()

	if _target != null and position.distance_to(_target.position) <= attack_range:
		velocity = Vector2.ZERO
		if _attack_timer <= 0.0:
			_do_attack()
	else:
		var goal := _target.position if _target != null else _enemy_king_pos
		var dir := (goal - position).normalized()
		velocity = dir * move_speed
		move_and_slide()

func _find_target() -> void:
	var enemy_team := 1 - owner_player
	var best: Node2D = null
	var best_dist := INF

	if not targets_structures_only:
		for node in get_tree().get_nodes_in_group("troops"):
			var t := node as TroopUnit
			if t == null or not t.is_alive or t.owner_player != enemy_team:
				continue
			var d := position.distance_to(t.position)
			if d < attack_range * 2.5 and d < best_dist:
				best_dist = d
				best = t

	if best == null:
		for node in get_tree().get_nodes_in_group("towers"):
			var t := node as Tower
			if t == null or not t.is_alive or t.owner_player != enemy_team:
				continue
			var d := position.distance_to(t.position)
			if d < best_dist:
				best_dist = d
				best = t

	_target = best

func _do_attack() -> void:
	_attack_timer = 1.0 / attack_speed
	if _target == null:
		return
	if _target is TroopUnit:
		(_target as TroopUnit).take_damage(attack_damage)
	elif _target is Tower:
		(_target as Tower).take_damage(attack_damage)

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
	remove_from_group("troops")
	queue_free()
