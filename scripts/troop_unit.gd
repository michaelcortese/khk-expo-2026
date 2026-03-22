class_name TroopUnit
extends CharacterBody2D

var owner_player: int             = 0
var move_speed: float             = 80.0
var max_hp: int                   = 200
var hp: int                       = 0
var is_alive: bool                = true
var attack_damage: int            = 30
var attack_range: float           = 55.0
var attack_speed: float           = 1.0
var targets_structures_only: bool = false

var _target: Node2D              = null
var _enemy_king_pos: Vector2     = Vector2.ZERO
var _attack_timer: float         = 0.0
var _spawn_lane: int             = 0   # 0 = top (y<240), 1 = bottom (y>=240)

func init(card: CardData, player_idx: int, enemy_king_position: Vector2) -> void:
	owner_player            = player_idx
	_enemy_king_pos         = enemy_king_position
	_spawn_lane             = 0 if position.y < 240 else 1
	max_hp                  = card.max_hp
	hp                      = card.max_hp
	attack_damage           = card.attack_damage
	attack_range            = card.attack_range
	attack_speed            = card.attack_speed
	move_speed              = card.move_speed
	targets_structures_only = card.targets_structures_only
	set_meta("card_id", card.card_id)
	add_to_group("troops")

func _ready() -> void:
	_build_visuals()

func _build_visuals() -> void:
	# Team tint blended with troop-type color
	var type_col: Color
	match get_meta("card_id", "knight"):
		"knight":    type_col = Color(0.6, 0.6, 0.6)   # gray
		"archer":    type_col = Color(0.6, 0.2, 0.8)   # purple
		"giant":     type_col = Color(0.5, 0.3, 0.1)   # brown
		"barbarian": type_col = Color(1.0, 0.85, 0.0)  # yellow
		_:           type_col = Color(1.0, 1.0, 1.0)

	var team_col := Color(0.0, 0.4, 1.0) if owner_player == 0 else Color(1.0, 0.1, 0.1)
	var col := type_col.lerp(team_col, 0.35)

	var body := Polygon2D.new()
	body.color   = col
	body.polygon = PackedVector2Array([
		Vector2(-10, -10), Vector2(10, -10),
		Vector2(10, 10),   Vector2(-10, 10)
	])
	add_child(body)

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
		velocity = (goal - position).normalized() * move_speed
		move_and_slide()

func _find_target() -> void:
	var enemy_team := 1 - owner_player
	var best: Node2D = null
	var best_dist    := INF

	# 1. Nearest enemy troop within 2.5x attack range
	if not targets_structures_only:
		for node in get_tree().get_nodes_in_group("troops"):
			if node.get("owner_player") != enemy_team:
				continue
			if not node.get("is_alive"):
				continue
			var d := position.distance_to(node.position)
			if d < attack_range * 2.5 and d < best_dist:
				best_dist = d
				best = node

	# 2. Any enemy tower already in attack range — attack the closest one
	if best == null:
		for node in get_tree().get_nodes_in_group("towers"):
			if node.get("owner_player") != enemy_team:
				continue
			if not node.get("is_alive"):
				continue
			var d := position.distance_to(node.position)
			if d <= attack_range and d < best_dist:
				best_dist = d
				best = node

	# 3. Walk toward the enemy princess tower in our lane
	if best == null:
		best_dist = INF
		for node in get_tree().get_nodes_in_group("towers"):
			if node.get("owner_player") != enemy_team:
				continue
			if not node.get("is_alive"):
				continue
			if node.get("is_king_tower"):
				continue
			# Match lane: top = y < 240, bottom = y >= 240
			var node_lane := 0 if node.position.y < 240 else 1
			if node_lane != _spawn_lane:
				continue
			var d := position.distance_to(node.position)
			if d < best_dist:
				best_dist = d
				best = node

	# 4. Lane princess tower is gone — target king tower
	if best == null:
		best_dist = INF
		for node in get_tree().get_nodes_in_group("towers"):
			if node.get("owner_player") != enemy_team:
				continue
			if not node.get("is_alive"):
				continue
			if not node.get("is_king_tower"):
				continue
			var d := position.distance_to(node.position)
			if d < best_dist:
				best_dist = d
				best = node

	_target = best

func _do_attack() -> void:
	_attack_timer = 1.0 / attack_speed
	if _target != null:
		_target.call("take_damage", attack_damage)

func take_damage(amount: int) -> void:
	if not is_alive:
		return
	hp = max(0, hp - amount)
	if hp == 0:
		_die()

func _die() -> void:
	is_alive = false
	remove_from_group("troops")
	queue_free()
