class_name Tower
extends StaticBody2D

signal destroyed

var _audio: Node = null

var owner_player: int   = 0
var is_king_tower: bool = false
var max_hp: int         = 1400
var hp: int             = 0
var is_alive: bool      = true

var _attack_timer: float = 0.0
var _target: Node2D      = null
var _is_active: bool     = false   # king towers start dormant

const ATTACK_DAMAGE: int   = 40
const ATTACK_RANGE: float  = 200.0
const ATTACK_SPEED: float  = 0.8   # attacks per second
# Slightly larger bolt for tower — cyan tint to distinguish from archer gold
const BOLT_COLOR: Color    = Color(0.35, 0.80, 1.00)

func _ready() -> void:
	hp = max_hp
	_is_active = not is_king_tower   # princess towers are always active
	add_to_group("towers")
	queue_redraw()
	_audio = get_tree().get_first_node_in_group("audio_manager")

func activate() -> void:
	_is_active = true
	queue_redraw()

func _process(delta: float) -> void:
	if not is_alive:
		return
	if is_king_tower and not _is_active:
		return
	# Drive continuous redraws while HP is critical so the pulse animates
	if float(hp) / float(max_hp) < 0.25:
		queue_redraw()
	_attack_timer -= delta
	_validate_target()
	if _target == null:
		_acquire_target()
	if _attack_timer <= 0.0 and _target != null:
		_fire()

# ── Target management ─────────────────────────────────────────────────────────

func _validate_target() -> void:
	if _target == null:
		return
	# Drop the target if it's been freed, marked dead, or walked out of range
	if not is_instance_valid(_target):
		_target = null
		return
	if not _target.get("is_alive"):
		_target = null
		return
	if position.distance_to(_target.position) > ATTACK_RANGE:
		_target = null

func _acquire_target() -> void:
	var enemy_team  := 1 - owner_player
	var nearest: Node2D = null
	var nearest_dist    := ATTACK_RANGE

	for node in get_tree().get_nodes_in_group("troops"):
		if node.get("owner_player") != enemy_team:
			continue
		if not node.get("is_alive"):
			continue
		var d := position.distance_to(node.position)
		if d < nearest_dist:
			nearest_dist = d
			nearest      = node

	_target = nearest

# ── Firing ────────────────────────────────────────────────────────────────────

func _fire() -> void:
	_attack_timer = 1.0 / ATTACK_SPEED
	if _target == null or not is_instance_valid(_target):
		return
	var bolt := Node2D.new()
	bolt.set_script(load("res://scripts/arrow.gd"))
	get_parent().add_child(bolt)
	bolt.call("launch", global_position, _target, ATTACK_DAMAGE, BOLT_COLOR)

# ── Damage / death ────────────────────────────────────────────────────────────

func take_damage(amount: int) -> void:
	if not is_alive:
		return
	hp = max(0, hp - amount)
	queue_redraw()
	_spawn_damage_number(amount)
	if _audio == null:
		_audio = get_tree().get_first_node_in_group("audio_manager")
	if _audio:
		_audio.play("tower_hit", -6.0)
	if hp == 0:
		_die()

func _spawn_damage_number(amount: int) -> void:
	if get_parent() == null:
		return
	var dn := Node2D.new()
	dn.set_script(load("res://scripts/damage_number.gd"))
	get_parent().add_child(dn)
	dn.call("setup", amount, global_position + Vector2(randf_range(-10.0, 10.0), -46.0))

func _draw() -> void:
	if not is_alive:
		return
	# Dormant king tower — grey overlay + greyed bar
	if is_king_tower and not _is_active:
		draw_rect(Rect2(-30, -30, 60, 60), Color(0, 0, 0, 0.50))
		draw_string(ThemeDB.fallback_font, Vector2(-10, 8), "ZZZ",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.55, 0.55, 0.60, 0.9))
		var bw := 64.0;  var bh := 8.0
		var bx := -bw * 0.5;  var by := -46.0
		draw_rect(Rect2(bx, by, bw, bh), Color(0.10, 0.10, 0.10))
		draw_rect(Rect2(bx, by, bw, bh), Color(0.30, 0.30, 0.30))
		draw_rect(Rect2(bx, by, bw, bh), Color(0, 0, 0, 0.6), false, 1.0)
		return
	var pct   := float(hp) / float(max_hp)
	var bar_w := 64.0
	var bar_h :=  8.0
	var bx    := -bar_w * 0.5
	var by    := -46.0
	draw_rect(Rect2(bx, by, bar_w, bar_h), Color(0.15, 0.15, 0.15))
	var fill_col: Color
	if pct > 0.5:
		fill_col = Color(0.1, 0.85, 0.1)
	elif pct > 0.25:
		fill_col = Color(0.95, 0.75, 0.05)
	else:
		fill_col = Color(0.90, 0.15, 0.10)
	draw_rect(Rect2(bx, by, bar_w * pct, bar_h), fill_col)
	draw_rect(Rect2(bx, by, bar_w, bar_h), Color(0, 0, 0, 0.6), false, 1.0)
	# Critical HP — pulsing red danger overlay
	if pct < 0.25:
		var t := sin(Time.get_ticks_msec() * 0.008) * 0.5 + 0.5
		draw_rect(Rect2(-30, -30, 60, 60), Color(1.0, 0.05, 0.05, t * 0.38))

func _die() -> void:
	is_alive = false
	_target  = null
	modulate = Color(0.3, 0.3, 0.3, 0.7)
	remove_from_group("towers")
	destroyed.emit()

# Like _die() but does NOT emit destroyed — used when king death sweeps remaining towers.
func destroy_silently() -> void:
	if not is_alive:
		return
	is_alive = false
	_target  = null
	modulate = Color(0.3, 0.3, 0.3, 0.7)
	remove_from_group("towers")
