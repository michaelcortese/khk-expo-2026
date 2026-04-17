class_name TroopUnit
extends CharacterBody2D

enum UnitState { IDLE, WALK, ATTACK, DEAD }

var owner_player: int             = 0
var move_speed: float             = 80.0
var max_hp: int                   = 200
var hp: int                       = 0
var is_alive: bool                = true
var attack_damage: int            = 30
var attack_range: float           = 55.0
var attack_speed: float           = 1.0
var targets_structures_only: bool = false
var is_ranged: bool               = false
var is_splash: bool               = false
var splash_radius: float          = 0.0

var _audio: Node = null
var _losing_hp_tex: Texture2D = null

var _target: Node2D              = null
var _enemy_king_pos: Vector2     = Vector2.ZERO
var _spawn_lane: int             = 0   # 0 = top (y<240), 1 = bottom (y>=240)
var _state: UnitState            = UnitState.IDLE
var _sprite: Node2D              = null
var _facing_right: bool          = true

# River / bridge constants (must match field_bg.gd and game_manager.gd)
const RIVER_LEFT    := 455.0
const RIVER_RIGHT   := 505.0
const BRIDGE_TOP_CY := 120.0
const BRIDGE_BOT_CY := 360.0

# Waypoint pathing
var _waypoints: Array[Vector2] = []
var _wp_idx: int               = 0
const WP_REACH_DIST: float     = 14.0

# Target polling
var _poll_counter: int = 0
const POLL_EVERY: int  = 8

# Attack timing: damage fires at DAMAGE_FRACTION into the swing, not at the start
# _attack_timer counts down from (1/attack_speed) to 0 — one full attack cycle
var _attack_timer: float   = 0.0
var _damage_dealt: bool    = false
const DAMAGE_FRACTION: float = 0.35   # 35% into the swing = damage frame

# Spawn delay: troops freeze for this many seconds after appearing
var _spawn_delay: float = 0.0
const SPAWN_DELAY: float = 0.55

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
	is_ranged               = card.is_ranged
	is_splash               = card.is_splash
	splash_radius           = card.splash_radius
	set_meta("card_id", card.card_id)
	_losing_hp_tex = load("res://assets/hitpoints_assets/losing_hp.png") as Texture2D
	add_to_group("troops")
	collision_layer = 2   # troops are on layer 2 — don't physically block each other
	collision_mask  = 4   # only blocked by layer 3 (river walls) — not by tower shapes
	_build_visuals()   # called here so card_id is set before choosing color
	_compute_path()
	_poll_counter = POLL_EVERY   # trigger target scan on first frame
	_spawn_delay  = SPAWN_DELAY
	# Pop-in scale animation during spawn delay
	scale = Vector2(0.1, 0.1)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), SPAWN_DELAY * 0.7) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _compute_path() -> void:
	var bridge_y := BRIDGE_TOP_CY if _spawn_lane == 0 else BRIDGE_BOT_CY
	_waypoints.clear()
	_wp_idx = 0
	if owner_player == 0 and position.x < RIVER_LEFT:
		_waypoints.append(Vector2(RIVER_LEFT  - 5.0, bridge_y))
		_waypoints.append(Vector2(RIVER_RIGHT + 5.0, bridge_y))
	elif owner_player == 1 and position.x > RIVER_RIGHT:
		_waypoints.append(Vector2(RIVER_RIGHT + 5.0, bridge_y))
		_waypoints.append(Vector2(RIVER_LEFT  - 5.0, bridge_y))

func _ready() -> void:
	queue_redraw()
	# Visuals built in init() after card_id is set — nothing to do here.

func _build_visuals() -> void:
	if _sprite != null:
		return   # already built

	var s := Node2D.new()
	s.set_script(load("res://scripts/troop_sprite.gd"))
	add_child(s)
	s.call("setup", get_meta("card_id", "knight"), owner_player)
	# Giant is larger; scale it up so it reads as a big threat on screen
	if get_meta("card_id", "knight") == "giant":
		s.scale = Vector2(1.35, 1.35)
	_sprite = s

# ── State machine ─────────────────────────────────────────────────────────────

func _set_state(new_state: UnitState) -> void:
	if _state == new_state:
		return
	_state = new_state
	_on_state_entered(new_state)

func _on_state_entered(s: UnitState) -> void:
	match s:
		UnitState.IDLE:
			if _sprite: _sprite.call("set_anim_state", "idle")
		UnitState.WALK:
			if _sprite: _sprite.call("set_anim_state", "walk")
		UnitState.ATTACK:
			if _sprite: _sprite.call("set_anim_state", "attack")
			# Bright flash at the start of each swing
			if _sprite:
				var tw := create_tween()
				tw.tween_property(_sprite, "modulate", Color(2.0, 2.0, 2.0), 0.07)
				tw.tween_property(_sprite, "modulate", Color(1.0, 1.0, 1.0), 0.13)
		UnitState.DEAD:
			if _sprite: _sprite.call("set_anim_state", "idle")
			is_alive = false
			remove_from_group("troops")
			_start_death_tween()

func _start_death_tween() -> void:
	# Fade + shrink over 0.45 s, then free.
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "modulate:a", 0.0, 0.45)
	tw.tween_property(self, "scale",      Vector2(0.4, 0.4), 0.45)
	tw.set_parallel(false)
	tw.tween_callback(queue_free)

# ── Physics ───────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if _state == UnitState.DEAD:
		return
	if _spawn_delay > 0.0:
		_spawn_delay -= delta
		return

	# Poll for nearest target every POLL_EVERY frames
	_poll_counter += 1
	if _poll_counter >= POLL_EVERY:
		_poll_counter = 0
		_find_target()

	# Advance bridge waypoints
	if _wp_idx < _waypoints.size():
		if position.distance_to(_waypoints[_wp_idx]) <= WP_REACH_DIST:
			_wp_idx += 1

	var in_range := _target != null \
		and is_instance_valid(_target) \
		and position.distance_to(_target.position) <= attack_range

	if in_range:
		_handle_attack(delta)
	else:
		_handle_movement(delta)

func _handle_attack(delta: float) -> void:
	velocity = Vector2.ZERO

	_attack_timer -= delta
	if _attack_timer <= 0.0:
		# Begin a new attack swing
		_attack_timer  = 1.0 / attack_speed
		_damage_dealt  = false
		_set_state(UnitState.ATTACK)   # triggers flash tween

	# Damage fires at DAMAGE_FRACTION into the swing
	var damage_threshold := (1.0 / attack_speed) * (1.0 - DAMAGE_FRACTION)
	if not _damage_dealt and _attack_timer <= damage_threshold:
		_damage_dealt = true
		if _target != null and is_instance_valid(_target):
			if is_ranged:
				_spawn_arrow()
				_play_sfx("arrow", -8.0)
			else:
				_target.call("take_damage", attack_damage)
				_play_sfx("hit", -6.0)
				_spawn_swing_effect()

func _play_sfx(name: String, vol: float = 0.0) -> void:
	if _audio == null:
		_audio = get_tree().get_first_node_in_group("audio_manager")
	if _audio:
		_audio.play(name, vol)

func _spawn_arrow() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	var arrow := Node2D.new()
	arrow.set_script(load("res://scripts/arrow.gd"))
	get_parent().add_child(arrow)
	var col := Color(0.20, 0.55, 1.0) if owner_player == 0 else Color(1.0, 0.20, 0.20)
	arrow.call("launch", global_position, _target, attack_damage, col,
			splash_radius if is_splash else 0.0, owner_player)

func _handle_movement(delta: float) -> void:
	var goal: Vector2
	if _wp_idx < _waypoints.size():
		goal = _waypoints[_wp_idx]
	elif _target != null and is_instance_valid(_target):
		goal = _target.position
	else:
		goal = _enemy_king_pos

	var dir := (goal - position).normalized()

	# Steer around any tower that is not the current target.
	# Uses repulsion + a perpendicular nudge so troops arc around the side
	# instead of pushing head-on and stopping.
	const AVOID_RADIUS   := 95.0
	const AVOID_STRENGTH := 5.0
	for tower in get_tree().get_nodes_in_group("towers"):
		if tower == _target:
			continue
		if not is_instance_valid(tower):
			continue
		var to_away: Vector2 = position - tower.position
		var dist: float      = to_away.length()
		if dist < AVOID_RADIUS and dist > 0.5:
			var away_norm: Vector2 = to_away.normalized()
			var strength: float    = (AVOID_RADIUS - dist) / AVOID_RADIUS
			# Push directly away
			dir += away_norm * strength * AVOID_STRENGTH
			# Also nudge sideways toward whichever side is more aligned with goal
			var perp_a: Vector2 = Vector2(-away_norm.y,  away_norm.x)
			var perp_b: Vector2 = Vector2( away_norm.y, -away_norm.x)
			var perp: Vector2   = perp_a if dir.dot(perp_a) >= dir.dot(perp_b) else perp_b
			dir += perp * strength * AVOID_STRENGTH * 0.7

	velocity = dir.normalized() * move_speed
	_update_facing()
	move_and_slide()

	if velocity.length_squared() > 1.0:
		_set_state(UnitState.WALK)
	else:
		_set_state(UnitState.IDLE)

func _update_facing() -> void:
	# Determine 4-way direction from velocity
	var dir := "right"
	if abs(velocity.y) > abs(velocity.x):
		dir = "down" if velocity.y > 0.0 else "up"
	else:
		if velocity.x > 5.0:
			_facing_right = true
			dir = "right"
		elif velocity.x < -5.0:
			_facing_right = false
			dir = "left"
		else:
			dir = "right" if _facing_right else "left"

	if _sprite:
		_sprite.call("set_direction", dir)
		# Sprite-sheet units have explicit left/right frames — no scale flip needed
		var cid: String = get_meta("card_id", "")
		if cid not in ["knight", "archer", "mini_pekka", "goblin_gang", "spear_goblin"]:
			_sprite.scale.x = abs(_sprite.scale.x) * (1.0 if _facing_right else -1.0)

# ── Target acquisition ────────────────────────────────────────────────────────

func _find_target() -> void:
	var enemy_team := 1 - owner_player

	# Pre-pass: find the tower we are marching toward (lane princess → king).
	# Used to prevent targeting troops that are behind a tower we haven't killed yet.
	var march_tower: Node2D = null
	var march_dist          := INF
	for node in get_tree().get_nodes_in_group("towers"):
		if node.get("owner_player") != enemy_team:
			continue
		if not node.get("is_alive"):
			continue
		if node.get("is_king_tower"):
			continue
		var node_lane := 0 if node.position.y < 240 else 1
		if node_lane != _spawn_lane:
			continue
		var d := position.distance_to(node.position)
		if d < march_dist:
			march_dist  = d
			march_tower = node
	if march_tower == null:
		# Lane princess gone — king tower is the march target
		for node in get_tree().get_nodes_in_group("towers"):
			if node.get("owner_player") != enemy_team:
				continue
			if not node.get("is_alive"):
				continue
			if not node.get("is_king_tower"):
				continue
			var d := position.distance_to(node.position)
			if d < march_dist:
				march_dist  = d
				march_tower = node

	var best: Node2D = null
	var best_dist    := INF

	# 1. Nearest enemy troop within 2.5x attack range AND closer than the march tower.
	#    The second condition stops units from chasing troops hiding behind a tower.
	if not targets_structures_only:
		for node in get_tree().get_nodes_in_group("troops"):
			if node.get("owner_player") != enemy_team:
				continue
			if not node.get("is_alive"):
				continue
			var d := position.distance_to(node.position)
			if d < attack_range * 2.5 and d < best_dist and d < march_dist:
				best_dist = d
				best      = node

	# 2. Enemy tower already in attack range
	if best == null:
		best_dist = INF
		for node in get_tree().get_nodes_in_group("towers"):
			if node.get("owner_player") != enemy_team:
				continue
			if not node.get("is_alive"):
				continue
			var d := position.distance_to(node.position)
			if d <= attack_range and d < best_dist:
				best_dist = d
				best      = node

	# 3. March toward the pre-computed tower
	if best == null:
		best = march_tower

	_target = best

# ── Damage / death ────────────────────────────────────────────────────────────

func take_damage(amount: int) -> void:
	if _state == UnitState.DEAD:
		return
	hp = max(0, hp - amount)
	queue_redraw()
	_spawn_damage_number(amount)
	_spawn_losing_hp()
	# Hit-flash
	if _sprite and hp > 0:
		var tw := create_tween()
		tw.tween_property(_sprite, "modulate", Color(2.5, 0.4, 0.4), 0.05)
		tw.tween_property(_sprite, "modulate", Color(1.0, 1.0, 1.0), 0.10)
	if hp == 0:
		_set_state(UnitState.DEAD)

func _spawn_damage_number(amount: int) -> void:
	if get_parent() == null:
		return
	var dn := Node2D.new()
	dn.set_script(load("res://scripts/damage_number.gd"))
	get_parent().add_child(dn)
	dn.call("setup", amount, global_position + Vector2(randf_range(-8.0, 8.0), -18.0))

func _spawn_swing_effect() -> void:
	if get_parent() == null:
		return
	var frames: Array = [
		load("res://assets/hitpoints_assets/sword_swing_frame2.png") as Texture2D,
		load("res://assets/hitpoints_assets/sword_swing_frame3.png") as Texture2D,
	]
	var sp := Sprite2D.new()
	sp.texture        = frames[0]
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.scale          = Vector2(2.0, 2.0)
	sp.flip_h         = not _facing_right
	var hit_pos: Vector2 = _target.global_position \
			if _target != null and is_instance_valid(_target) \
			else global_position
	sp.position = hit_pos
	get_parent().add_child(sp)
	const FRAME_DUR := 0.07
	var tw := create_tween()
	tw.tween_interval(FRAME_DUR)
	tw.tween_callback(func(): sp.texture = frames[1])
	tw.tween_interval(FRAME_DUR)
	tw.tween_callback(sp.queue_free)

func _spawn_losing_hp() -> void:
	if _losing_hp_tex == null or get_parent() == null:
		return
	var by: float = -34.0 if get_meta("card_id", "") == "giant" else -28.0
	var sp := Sprite2D.new()
	sp.texture        = _losing_hp_tex
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.scale          = Vector2(1.5, 1.5)
	sp.position       = global_position + Vector2(20.0, by)
	get_parent().add_child(sp)
	var tw := sp.create_tween().set_parallel(true)
	tw.tween_property(sp, "position:y", sp.position.y - 14.0, 0.6)
	tw.tween_property(sp, "modulate:a", 0.0,                  0.6)
	tw.set_parallel(false)
	tw.tween_callback(sp.queue_free)

func _draw() -> void:
	if _state == UnitState.DEAD:
		return
	var pct   := float(hp) / float(max_hp)
	var bar_w := 30.0
	var bar_h :=  5.0
	var bx    := -bar_w * 0.5
	# Giant is taller, push the bar above its head
	var by    := -34.0 if get_meta("card_id", "") == "giant" else -28.0
	var fill_w  := bar_w * pct
	var top_h   := bar_h * 0.58
	var bot_h   := bar_h - top_h
	var col_top := Color(0.30, 0.70, 1.00) if owner_player == 0 else Color(0.95, 0.15, 0.10)
	var col_bot := Color(0.08, 0.08, 0.82) if owner_player == 0 else Color(0.48, 0.05, 0.05)
	draw_rect(Rect2(bx, by, bar_w, bar_h), Color(0.05, 0.05, 0.05))
	draw_rect(Rect2(bx, by + top_h, fill_w, bot_h), col_bot)
	draw_rect(Rect2(bx, by,         fill_w, top_h), col_top)
	draw_rect(Rect2(bx, by, bar_w, bar_h), Color(0, 0, 0, 0.85), false, 2.0)
