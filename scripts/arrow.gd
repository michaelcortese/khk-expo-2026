extends Node2D

# Projectile spawned by ranged units.
# Supports single-target and splash (AoE) damage.

const SPEED: float = 380.0

var _target_node:  Node2D  = null
var _target_pos:   Vector2 = Vector2.ZERO
var _damage:       int     = 0
var _direction:    Vector2 = Vector2.RIGHT
var _arrived:      bool    = false
var _shaft:        Polygon2D = null
var _splash_radius: float  = 0.0
var _owner_player:  int    = -1   # needed to identify enemies for splash

# Called immediately after add_child() by the spawning unit.
# proj_color defaults to archer gold.
# Pass splash_radius > 0 to make this an AoE orb.
# owner_player must be set for splash to know which team to damage.
func launch(from: Vector2, target: Node2D, dmg: int,
		proj_color: Color = Color(0.85, 0.70, 0.25),
		splash_radius: float = 0.0, owner_player: int = -1) -> void:
	_target_node    = target
	_target_pos     = target.global_position
	_damage         = dmg
	_splash_radius  = splash_radius
	_owner_player   = owner_player
	_direction      = (_target_pos - from).normalized()
	global_position = from
	rotation        = _direction.angle()
	_build_visual(proj_color)

func _build_visual(col: Color) -> void:
	_shaft       = Polygon2D.new()
	_shaft.color = col
	if _splash_radius > 0.0:
		# Circular orb for splash projectiles
		var pts := PackedVector2Array()
		for i in range(12):
			var a := TAU * float(i) / 12.0
			pts.append(Vector2(cos(a), sin(a)) * 7.0)
		_shaft.polygon = pts
	else:
		# Arrow shaft — pentagon with pointed tip along +x
		_shaft.polygon = PackedVector2Array([
			Vector2(-9,  -1.5),
			Vector2( 7,  -1.5),
			Vector2( 9,   0.0),
			Vector2( 7,   1.5),
			Vector2(-9,   1.5)
		])
	add_child(_shaft)

func _process(delta: float) -> void:
	if _arrived:
		return
	var step      := SPEED * delta
	var remaining := global_position.distance_to(_target_pos)
	if step >= remaining:
		global_position = _target_pos
		_arrived = true
		_on_arrive()
	else:
		global_position += _direction * step

func _on_arrive() -> void:
	if _splash_radius > 0.0:
		var enemy_team := 1 - _owner_player
		for node in get_tree().get_nodes_in_group("troops"):
			if node.get("owner_player") != enemy_team:
				continue
			if not node.get("is_alive"):
				continue
			if _target_pos.distance_to(node.position) <= _splash_radius:
				node.call("take_damage", _damage)
		for node in get_tree().get_nodes_in_group("towers"):
			if node.get("owner_player") != enemy_team:
				continue
			if not node.get("is_alive"):
				continue
			if _target_pos.distance_to(node.position) <= _splash_radius:
				node.call("take_damage", _damage)
	else:
		if _target_node != null and is_instance_valid(_target_node):
			_target_node.call("take_damage", _damage)
	_play_hit_effect()

func _play_hit_effect() -> void:
	if _shaft == null:
		queue_free()
		return
	var end_scale := Vector2(5.0, 5.0) if _splash_radius > 0.0 else Vector2(2.2, 2.2)
	var duration  := 0.20                if _splash_radius > 0.0 else 0.12
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_shaft, "scale",      end_scale, duration)
	tw.tween_property(_shaft, "modulate:a", 0.0,       duration)
	tw.set_parallel(false)
	tw.tween_callback(queue_free)
