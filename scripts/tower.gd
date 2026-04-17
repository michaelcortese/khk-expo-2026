class_name Tower
extends StaticBody2D

signal destroyed

var _audio: Node = null

var owner_player: int   = 0
var is_king_tower: bool = false
var max_hp: int         = 1400
var hp: int             = 0
var is_alive: bool      = true

var _attack_timer: float   = 0.0
var _pulse_timer:  float   = 0.0
var _target: Node2D        = null
var _is_active: bool       = false   # king towers start dormant
var _losing_hp_tex: Texture2D = null

const ATTACK_DAMAGE: int   = 40
const ATTACK_RANGE: float  = 200.0
const ATTACK_SPEED: float  = 0.8   # attacks per second
# Slightly larger bolt for tower — cyan tint to distinguish from archer gold
const BOLT_COLOR: Color    = Color(0.35, 0.80, 1.00)

# Sprite animation
var _tower_sprite: Sprite2D        = null
var _normal_frames: Array          = []      # Array[Texture2D] — 2 walk frames
var _surrender_frames: Array       = []      # Array[Texture2D] — 2 surrender frames
var _sprite_frame_timer: float     = 0.0
var _sprite_cur_frame: int         = 0
const SPRITE_FRAME_INTERVAL: float = 0.55   # seconds between frame flips

func _ready() -> void:
	hp = max_hp
	_is_active = not is_king_tower   # princess towers are always active
	add_to_group("towers")
	queue_redraw()
	_audio = get_tree().get_first_node_in_group("audio_manager")
	_losing_hp_tex = load("res://assets/hitpoints_assets/losing_hp.png") as Texture2D

# Called by GameManager after owner_player and tower number are known.
func setup_sprite(player_idx: int, tower_num: int) -> void:
	var color := "blue" if player_idx == 0 else "red"

	# King tower (tower_num == 0) — single static image, no animation
	if tower_num == 0:
		var path := "res://assets/towers_assets/%s_king_tower.png" % color
		if not ResourceLoader.exists(path):
			return
		for child in get_children():
			if child is ColorRect:
				child.visible = false
		_tower_sprite                = Sprite2D.new()
		_tower_sprite.texture        = load(path) as Texture2D
		_tower_sprite.scale          = Vector2(2.0, 2.0)
		_tower_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_tower_sprite.position       = Vector2(0.0, -8.0)
		add_child(_tower_sprite)
		return

	# Princess towers — 2-frame walk + surrender animation
	var base    := "res://assets/towers_assets/%s_princess_%d_" % [color, tower_num]
	var f1_path := base + "frame1.png"
	var f2_path := base + "frame2.png"
	var s1_path := base + "surrender_frame1.png"
	var s2_path := base + "surrender_frame2.png"

	if not ResourceLoader.exists(f1_path):
		return

	_normal_frames    = [load(f1_path), load(f2_path)]
	_surrender_frames = [load(s1_path), load(s2_path)]

	for child in get_children():
		if child is ColorRect:
			child.visible = false

	_tower_sprite                = Sprite2D.new()
	_tower_sprite.texture        = _normal_frames[0]
	_tower_sprite.scale          = Vector2(2.0, 2.0)
	_tower_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_tower_sprite.position       = Vector2(0.0, -8.0)
	add_child(_tower_sprite)

func activate() -> void:
	_is_active = true
	queue_redraw()

func _process(delta: float) -> void:
	# Animate sprite frames (works even when dormant)
	if _tower_sprite != null and _normal_frames.size() == 2:
		_sprite_frame_timer += delta
		if _sprite_frame_timer >= SPRITE_FRAME_INTERVAL:
			_sprite_frame_timer -= SPRITE_FRAME_INTERVAL
			_sprite_cur_frame   = 1 - _sprite_cur_frame
			_tower_sprite.texture = _normal_frames[_sprite_cur_frame]

	if not is_alive:
		return
	if is_king_tower and not _is_active:
		return
	# Drive redraws while HP is critical for the pulse overlay (~20 fps is plenty)
	if float(hp) / float(max_hp) < 0.25:
		_pulse_timer += delta
		if _pulse_timer >= 0.05:
			_pulse_timer = 0.0
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
	_spawn_losing_hp()
	if _audio == null:
		_audio = get_tree().get_first_node_in_group("audio_manager")
	if _audio:
		_audio.play("tower_hit", -6.0)
	if hp == 0:
		_die()

func _spawn_losing_hp() -> void:
	if _losing_hp_tex == null or get_parent() == null:
		return
	var sp := Sprite2D.new()
	sp.texture        = _losing_hp_tex
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.scale          = Vector2(2.0, 2.0)
	sp.position       = global_position + Vector2(40.0, -90.0)
	get_parent().add_child(sp)
	var tw := sp.create_tween().set_parallel(true)
	tw.tween_property(sp, "position:y", sp.position.y - 20.0, 0.7)
	tw.tween_property(sp, "modulate:a", 0.0,                  0.7)
	tw.set_parallel(false)
	tw.tween_callback(sp.queue_free)

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
		var bx := -bw * 0.5;  var by := -90.0
		draw_rect(Rect2(bx, by, bw, bh), Color(0.10, 0.10, 0.10))
		draw_rect(Rect2(bx, by, bw, bh), Color(0.30, 0.30, 0.30))
		draw_rect(Rect2(bx, by, bw, bh), Color(0, 0, 0, 0.6), false, 1.0)
		return
	var pct   := float(hp) / float(max_hp)
	var bar_w := 64.0
	var bar_h :=  8.0
	var bx    := -bar_w * 0.5
	var by    := -90.0
	var fill_w  := bar_w * pct
	var top_h   := bar_h * 0.58
	var bot_h   := bar_h - top_h
	var col_top := Color(0.30, 0.70, 1.00) if owner_player == 0 else Color(0.95, 0.15, 0.10)
	var col_bot := Color(0.08, 0.08, 0.82) if owner_player == 0 else Color(0.48, 0.05, 0.05)
	draw_rect(Rect2(bx, by, bar_w, bar_h), Color(0.05, 0.05, 0.05))
	draw_rect(Rect2(bx, by + top_h, fill_w, bot_h), col_bot)
	draw_rect(Rect2(bx, by,         fill_w, top_h), col_top)
	draw_rect(Rect2(bx, by, bar_w, bar_h), Color(0, 0, 0, 0.85), false, 2.0)
	# Critical HP — pulsing red danger overlay
	if pct < 0.25:
		var t := sin(Time.get_ticks_msec() * 0.008) * 0.5 + 0.5
		draw_rect(Rect2(-30, -30, 60, 60), Color(1.0, 0.05, 0.05, t * 0.38))

func _switch_to_surrender() -> void:
	if _tower_sprite != null and _surrender_frames.size() == 2:
		_normal_frames   = _surrender_frames   # reuse anim loop with surrender frames
		_sprite_cur_frame = 0
		_tower_sprite.texture = _normal_frames[0]

func _die() -> void:
	is_alive = false
	_target  = null
	_switch_to_surrender()
	remove_from_group("towers")
	destroyed.emit()

# Like _die() but does NOT emit destroyed — used when king death sweeps remaining towers.
func destroy_silently() -> void:
	if not is_alive:
		return
	is_alive = false
	_target  = null
	_switch_to_surrender()
	remove_from_group("towers")
