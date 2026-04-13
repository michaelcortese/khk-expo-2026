class_name GameManager
extends Node2D

const P1_KING_POS := Vector2(900, 240)   # P1 troops march toward P2's king
const P2_KING_POS := Vector2(20,  240)   # P2 troops march toward P1's king

enum Phase { REGULAR, OVERTIME, SUDDEN_DEATH }

const ELIXIR_RATE_NORMAL: float = 1.0 / 2.8
const ELIXIR_RATE_FAST:   float = 2.0 / 2.8
const ELIXIR_MAX:         float = 10.0
const REGULAR_DURATION:   float = 180.0
const OVERTIME_DURATION:  float = 180.0
const SUDDEN_DEATH_DRAIN: float = 20.0   # HP per second drained from all towers

var p1_elixir: float = 5.0
var p2_elixir: float = 5.0

var _phase:                   Phase = Phase.REGULAR
var _match_timer:             float = REGULAR_DURATION
var _overtime_timer:          float = OVERTIME_DURATION
var _sd_drain_acc:            float = 0.0
var _p1_crowns:               int   = 0
var _p2_crowns:               int   = 0
var _last_minute_announced:   bool  = false

var p1_deck: Deck
var p2_deck: Deck

var _troop_scene: PackedScene
var _hud: HUD

func _ready() -> void:
	_troop_scene = load("res://troop.tscn")
	_setup_field()
	_setup_decks()
	_tag_towers()
	_setup_controllers()
	_setup_hud()
	_fit_camera_above_hud()
	_setup_river_walls()
	_setup_audio()

var _audio: Node = null

func _setup_audio() -> void:
	var script := load("res://scripts/audio_manager.gd")
	_audio = script.new()
	_audio.name = "AudioManager"
	add_child(_audio)

func _setup_field() -> void:
	var field_script := load("res://scripts/field_bg.gd")
	var field        := Node2D.new()
	field.set_script(field_script)
	add_child(field)
	move_child(field, 0)   # draw behind towers and troops

# ── Decks ─────────────────────────────────────────────────────────────────────
func _setup_decks() -> void:
	var cards := _make_cards()
	p1_deck = Deck.new()
	p1_deck.setup(cards)
	p2_deck = Deck.new()
	p2_deck.setup(cards)

func _make_cards() -> Array[CardData]:
	var list: Array[CardData] = []

	# ── Knight (3 elixir) ── Melee tank
	var knight := CardData.new()
	knight.card_id       = "knight"
	knight.display_name  = "Knight"
	knight.cost          = 3
	knight.max_hp        = 400
	knight.attack_damage = 60
	knight.attack_range  = 55.0
	knight.attack_speed  = 1.0
	knight.move_speed    = 38.0
	list.append(knight)

	# ── Archer (3 elixir) ── 2× single-target ranged
	var archer := CardData.new()
	archer.card_id       = "archer"
	archer.display_name  = "Archer"
	archer.cost          = 3
	archer.max_hp        = 130
	archer.attack_damage = 22
	archer.attack_range  = 145.0
	archer.attack_speed  = 1.2
	archer.move_speed    = 46.0
	archer.is_ranged     = true
	archer.troop_count   = 2
	list.append(archer)

	# ── Wizard (5 elixir) ── Splash ranged
	var wizard := CardData.new()
	wizard.card_id        = "wizard"
	wizard.display_name   = "Wizard"
	wizard.cost           = 5
	wizard.max_hp         = 280
	wizard.attack_damage  = 80
	wizard.attack_range   = 150.0
	wizard.attack_speed   = 0.65
	wizard.move_speed     = 32.0
	wizard.is_ranged      = true
	wizard.is_splash      = true
	wizard.splash_radius  = 60.0
	list.append(wizard)

	# ── Barbarian (5 elixir) ── 4× melee
	var barb := CardData.new()
	barb.card_id       = "barbarian"
	barb.display_name  = "Barbarian"
	barb.cost          = 5
	barb.max_hp        = 240
	barb.attack_damage = 55
	barb.attack_range  = 50.0
	barb.attack_speed  = 1.3
	barb.move_speed    = 44.0
	barb.troop_count   = 4
	list.append(barb)

	# ── Giant (5 elixir) ── Tank, targets structures only
	var giant := CardData.new()
	giant.card_id                 = "giant"
	giant.display_name            = "Giant"
	giant.cost                    = 5
	giant.max_hp                  = 800
	giant.attack_damage           = 60
	giant.attack_range            = 55.0
	giant.attack_speed            = 0.7
	giant.move_speed              = 32.0
	giant.targets_structures_only = true
	list.append(giant)

	# ── Hog Rider (4 elixir) ── Fast, targets structures only
	var hog := CardData.new()
	hog.card_id                 = "hog_rider"
	hog.display_name            = "Hog Rider"
	hog.cost                    = 4
	hog.max_hp                  = 350
	hog.attack_damage           = 80
	hog.attack_range            = 55.0
	hog.attack_speed            = 1.0
	hog.move_speed              = 62.0
	hog.targets_structures_only = true
	list.append(hog)

	# ── Mini Pekka (4 elixir) ── High-damage tank killer
	var mpekka := CardData.new()
	mpekka.card_id       = "mini_pekka"
	mpekka.display_name  = "Mini Pekka"
	mpekka.cost          = 4
	mpekka.max_hp        = 380
	mpekka.attack_damage = 140
	mpekka.attack_range  = 50.0
	mpekka.attack_speed  = 0.7
	mpekka.move_speed    = 40.0
	list.append(mpekka)

	# ── Goblin Gang (3 elixir) ── 3 melee goblins + 2 spear goblins
	var spear_goblin := CardData.new()
	spear_goblin.card_id       = "spear_goblin"
	spear_goblin.display_name  = "Spear Goblin"
	spear_goblin.cost          = 0   # part of Goblin Gang, no standalone cost
	spear_goblin.max_hp        = 60
	spear_goblin.attack_damage = 20
	spear_goblin.attack_range  = 130.0
	spear_goblin.attack_speed  = 1.3
	spear_goblin.move_speed    = 54.0
	spear_goblin.is_ranged     = true

	var goblin_gang := CardData.new()
	goblin_gang.card_id        = "goblin"
	goblin_gang.display_name   = "Goblin Gang"
	goblin_gang.cost           = 3
	goblin_gang.max_hp         = 80
	goblin_gang.attack_damage  = 30
	goblin_gang.attack_range   = 50.0
	goblin_gang.attack_speed   = 1.6
	goblin_gang.move_speed     = 56.0
	goblin_gang.troop_count    = 3
	goblin_gang.secondary_card  = spear_goblin
	goblin_gang.secondary_count = 2
	list.append(goblin_gang)

	return list

# ── Towers ────────────────────────────────────────────────────────────────────
var _game_over: bool = false

func _tag_towers() -> void:
	var defs: Array = [
		["King_Tower_P1",      0, true ],
		["Princess_Tower1_P1", 0, false],
		["Princess_Tower2_P1", 0, false],
		["King_Tower_P2",      1, true ],
		["Princess_Tower1_P2", 1, false],
		["Princess_Tower2_P2", 1, false],
	]
	for d in defs:
		var t := get_node_or_null(d[0])
		if t:
			t.set("owner_player",  d[1])
			t.set("is_king_tower", d[2])
			t.connect("destroyed", _on_tower_destroyed.bind(t))

# ── Controllers ───────────────────────────────────────────────────────────────
var _p1_controller: PlayerController
var _p2_controller: PlayerController

func _setup_controllers() -> void:
	_p1_controller              = PlayerController.new()
	_p1_controller.name         = "P1Controller"
	_p1_controller.player_index = 0
	_p1_controller.joy_device   = 0
	_p1_controller.zone_min     = Vector2(60,  0)
	_p1_controller.zone_max     = Vector2(455, 480)
	_p1_controller.cursor_color = Color(0.2, 0.6, 1.0, 0.9)
	add_child(_p1_controller)
	_p1_controller.card_played.connect(_on_card_played.bind(0))

	_p2_controller              = PlayerController.new()
	_p2_controller.name         = "P2Controller"
	_p2_controller.player_index = 1
	_p2_controller.joy_device   = 1
	_p2_controller.zone_min     = Vector2(505, 0)
	_p2_controller.zone_max     = Vector2(900, 480)
	_p2_controller.cursor_color = Color(1.0, 0.2, 0.2, 0.9)
	add_child(_p2_controller)
	_p2_controller.card_played.connect(_on_card_played.bind(1))

# ── HUD ───────────────────────────────────────────────────────────────────────
func _setup_hud() -> void:
	_hud = HUD.new()
	add_child(_hud)

func _fit_camera_above_hud() -> void:
	# Screen: 1280x1024. HUD occupies bottom 290px (y=734-1024).
	# Game world: approx x=-50..960, y=0..480.
	# zoom=1.1 keeps all towers on screen with margin:
	#   left edge  world x=-50  → screen x=57  (safe)
	#   right edge world x=930  → screen x=1135 (safe)
	# cam_y=372 centers the game vertically in the top 734px.
	var cam := get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		for child in get_children():
			if child is Camera2D:
				cam = child
				break
	if cam:
		cam.zoom     = Vector2(1.1, 1.1)
		cam.position = Vector2(480, 372)

func _update_hud() -> void:
	if _hud:
		_hud.update_hud(p1_elixir, p2_elixir, p1_deck, p2_deck)
		_hud.set_crowns(_p1_crowns, _p2_crowns)
		var remaining: float
		match _phase:
			Phase.REGULAR:
				remaining = maxf(0.0, _match_timer)
			Phase.OVERTIME:
				remaining = maxf(0.0, _overtime_timer)
			Phase.SUDDEN_DEATH:
				remaining = 0.0
		_hud.set_timer(remaining, _phase)
		var double_elixir := _phase != Phase.REGULAR or _match_timer < 60.0
		_hud.set_double_elixir(double_elixir)

# ── Win condition ─────────────────────────────────────────────────────────────
func _on_tower_destroyed(tower: Node) -> void:
	if _game_over:
		return
	var loser: int    = tower.get("owner_player")
	var attacker: int = 1 - loser
	var is_king: bool = tower.get("is_king_tower")

	# Screen shake — bigger for king tower
	_shake_camera(8.0 if is_king else 4.0, 0.35)

	# Audio
	if _audio:
		_audio.play("tower_destroy", 2.0 if is_king else 0.0)
		_audio.play("crown")

	# Particle burst + crown pop
	_spawn_tower_burst(tower.position, is_king)
	_spawn_crown_pop(tower.position)

	# Always count the crown (including king tower kill)
	if attacker == 0:
		_p1_crowns += 1
	else:
		_p2_crowns += 1

	if is_king:
		# Award crowns for any princess towers still standing on the losing side
		for node in get_tree().get_nodes_in_group("towers"):
			if node.get("owner_player") == loser and node.get("is_alive"):
				if attacker == 0:
					_p1_crowns += 1
				else:
					_p2_crowns += 1
				node.call("destroy_silently")
				_spawn_tower_burst(node.position, false)
		_declare_winner(attacker)
		return

	# Activate the defender's king tower when a princess falls
	for node in get_tree().get_nodes_in_group("towers"):
		if node.get("owner_player") == loser and node.get("is_king_tower"):
			node.call("activate")
			break

	match _phase:
		Phase.REGULAR:
			_expand_zone(tower)
		Phase.OVERTIME, Phase.SUDDEN_DEATH:
			_declare_winner(attacker)

func _expand_zone(tower: Node) -> void:
	# The player who destroyed this tower gets to deploy in the area it guarded.
	# The new rect MUST be contiguous with the attacker's existing zone so the
	# cursor can reach it without crossing a gap.
	# P1 main zone: x 60–490.  P2 main zone: x 510–900.
	var owner: int     = tower.get("owner_player")
	var attacker_ctrl  := _p1_controller if owner == 1 else _p2_controller
	var top_lane: bool = tower.position.y < 240
	var y_min: float   = 0.0   if top_lane else 240.0
	var y_max: float   = 240.0 if top_lane else 480.0

	if owner == 1:
		# P2's princess died → P1 gets the quarter near P2's princess (x 455 → 730)
		attacker_ctrl.add_zone(Rect2(455, y_min, 275, y_max - y_min))
	else:
		# P1's princess died → P2 gets the quarter near P1's princess (x 260 → 505)
		attacker_ctrl.add_zone(Rect2(260, y_min, 245, y_max - y_min))

func _end_regular_time() -> void:
	if _p1_crowns > _p2_crowns:
		_declare_winner(0)
	elif _p2_crowns > _p1_crowns:
		_declare_winner(1)
	else:
		_enter_overtime()

func _enter_overtime() -> void:
	_phase          = Phase.OVERTIME
	_overtime_timer = OVERTIME_DURATION
	_show_phase_banner("OVERTIME!")

func _enter_sudden_death() -> void:
	_phase = Phase.SUDDEN_DEATH
	_show_phase_banner("SUDDEN DEATH")

func _spawn_tower_burst(world_pos: Vector2, is_king: bool) -> void:
	var burst := Node2D.new()
	burst.set_script(load("res://scripts/tower_burst.gd"))
	add_child(burst)
	burst.call("start", world_pos, is_king)

func _spawn_crown_pop(world_pos: Vector2) -> void:
	var pop := Node2D.new()
	pop.set_script(load("res://scripts/crown_pop.gd"))
	add_child(pop)
	pop.call("start", world_pos)

func _shake_camera(intensity: float, duration: float) -> void:
	var cam: Camera2D = null
	for child in get_children():
		if child is Camera2D:
			cam = child
			break
	if cam == null:
		return
	var tw := create_tween()
	var steps := 8
	for i in range(steps):
		tw.tween_property(cam, "offset",
				Vector2(randf_range(-intensity, intensity),
						randf_range(-intensity, intensity)),
				duration / float(steps))
	tw.tween_property(cam, "offset", Vector2.ZERO, duration / float(steps))

func _show_phase_banner(text: String, col: Color = Color(1.0, 0.5, 0.0)) -> void:
	var cl := CanvasLayer.new()
	cl.layer = 9
	add_child(cl)

	var lbl := Label.new()
	lbl.text = text
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 72)
	lbl.add_theme_color_override("font_color", col)
	cl.add_child(lbl)

	var tw := create_tween()
	tw.tween_interval(1.5)
	tw.tween_property(lbl, "modulate:a", 0.0, 1.0)
	tw.tween_callback(cl.queue_free)

func _declare_winner(player_idx: int) -> void:
	_game_over = true
	if _audio:
		_audio.stop_music()
		_audio.play("victory", -2.0)
	_show_end_screen("PLAYER %d WINS!" % (player_idx + 1), _p1_crowns, _p2_crowns)

func _show_end_screen(msg: String, p1c: int = 0, p2c: int = 0) -> void:
	var cl := CanvasLayer.new()
	cl.layer = 10
	add_child(cl)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	cl.add_child(bg)

	var lbl := Label.new()
	lbl.text = msg
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.position = Vector2(0, -80)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 80)
	cl.add_child(lbl)

	var score := Label.new()
	score.text = "★ %d   —   %d ★" % [p1c, p2c]
	score.set_anchors_preset(Control.PRESET_FULL_RECT)
	score.position = Vector2(0, 30)
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	score.add_theme_font_size_override("font_size", 44)
	score.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	cl.add_child(score)

	var prompt := Label.new()
	prompt.text = "PRESS ANY BUTTON TO CONTINUE"
	prompt.set_anchors_preset(Control.PRESET_FULL_RECT)
	prompt.position = Vector2(0, 110)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 28)
	cl.add_child(prompt)

	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(prompt, "modulate:a", 0.15, 0.6)
	tween.tween_property(prompt, "modulate:a", 1.0,  0.6)

	_awaiting_menu = true

var _awaiting_menu: bool = false

func _input(event: InputEvent) -> void:
	# DEBUG — remove once button mapping is confirmed
	if event is InputEventJoypadButton and (event as InputEventJoypadButton).pressed:
		var e := event as InputEventJoypadButton
		print("JOY device=%d  button=%d  name=%s" % [e.device, e.button_index, JoyButton.keys()[e.button_index]])
	if event is InputEventJoypadMotion:
		var e := event as InputEventJoypadMotion
		if abs(e.axis_value) > 0.3:
			print("JOY device=%d  axis=%d  value=%.2f" % [e.device, e.axis, e.axis_value])

	if not _awaiting_menu:
		return
	var pressed := false
	if event is InputEventKey:
		pressed = (event as InputEventKey).pressed and not (event as InputEventKey).echo
	elif event is InputEventJoypadButton:
		pressed = (event as InputEventJoypadButton).pressed
	if pressed:
		get_tree().change_scene_to_file("res://main_menu.tscn")

# ── Elixir tick + phase logic ─────────────────────────────────────────────────
func _process(delta: float) -> void:
	if _game_over:
		return

	match _phase:
		Phase.REGULAR:
			_match_timer -= delta
			var rate := ELIXIR_RATE_FAST if _match_timer < 60.0 else ELIXIR_RATE_NORMAL
			p1_elixir = minf(ELIXIR_MAX, p1_elixir + rate * delta)
			p2_elixir = minf(ELIXIR_MAX, p2_elixir + rate * delta)
			if _match_timer < 60.0 and not _last_minute_announced:
				_last_minute_announced = true
				_show_phase_banner("LAST MINUTE!", Color(1.0, 0.25, 0.0))
			if _match_timer <= 0.0:
				_end_regular_time()

		Phase.OVERTIME:
			_overtime_timer -= delta
			p1_elixir = minf(ELIXIR_MAX, p1_elixir + ELIXIR_RATE_FAST * delta)
			p2_elixir = minf(ELIXIR_MAX, p2_elixir + ELIXIR_RATE_FAST * delta)
			if _overtime_timer <= 0.0:
				_enter_sudden_death()

		Phase.SUDDEN_DEATH:
			p1_elixir = minf(ELIXIR_MAX, p1_elixir + ELIXIR_RATE_FAST * delta)
			p2_elixir = minf(ELIXIR_MAX, p2_elixir + ELIXIR_RATE_FAST * delta)
			_sd_drain_acc += SUDDEN_DEATH_DRAIN * delta
			if _sd_drain_acc >= 1.0:
				var dmg := int(_sd_drain_acc)
				_sd_drain_acc -= float(dmg)
				for tower in get_tree().get_nodes_in_group("towers"):
					if tower.get("is_alive"):
						tower.call("take_damage", dmg)

	_update_hud()

# ── Card played ───────────────────────────────────────────────────────────────
func _on_card_played(slot: int, world_pos: Vector2, player_idx: int) -> void:
	if _game_over:
		return
	var deck   := p1_deck   if player_idx == 0 else p2_deck
	var elixir := p1_elixir if player_idx == 0 else p2_elixir
	var card   := deck.hand[slot]

	if elixir < float(card.cost):
		return
	if _audio:
		_audio.play("deploy")

	if player_idx == 0:
		p1_elixir -= float(card.cost)
	else:
		p2_elixir -= float(card.cost)

	deck.use_card(slot)
	_spawn_troop(card, player_idx, world_pos)

	# Deploy ring flash at cursor
	var flash := Node2D.new()
	flash.set_script(load("res://scripts/deploy_flash.gd"))
	add_child(flash)
	var fc := Color(0.2, 0.6, 1.0) if player_idx == 0 else Color(1.0, 0.2, 0.2)
	flash.call("start", world_pos, fc)

# ── Spawn ─────────────────────────────────────────────────────────────────────
func _spawn_troop(card: CardData, player_idx: int, pos: Vector2) -> void:
	var target := P1_KING_POS if player_idx == 0 else P2_KING_POS
	for i in range(card.troop_count):
		var off := Vector2.ZERO
		if card.troop_count > 1:
			off = Vector2(randf_range(-18.0, 18.0), randf_range(-18.0, 18.0))
		_spawn_one(card, player_idx, pos + off, target)
	if card.secondary_card != null and card.secondary_count > 0:
		var sec := card.secondary_card as CardData
		for i in range(card.secondary_count):
			var off := Vector2(randf_range(-18.0, 18.0), randf_range(-18.0, 18.0))
			_spawn_one(sec, player_idx, pos + off, target)

func _spawn_one(card: CardData, player_idx: int, pos: Vector2, target: Vector2) -> void:
	# Push spawn clear of river wall zone (x 455–505) to prevent troops getting stuck
	if pos.x > 440.0 and pos.x < 520.0:
		pos.x = 440.0 if player_idx == 0 else 520.0
	var troop := _troop_scene.instantiate() as Node2D
	troop.position = pos
	add_child(troop)
	troop.call("init", card, player_idx, target)

# ── River walls ────────────────────────────────────────────────────────────────
func _setup_river_walls() -> void:
	# Three wall segments either side of the bridge openings.
	# Must match constants in field_bg.gd and troop_unit.gd.
	var walls: Array[Rect2] = [
		Rect2(455, -80, 50, 150),   # top wall   (y -80 → 70)
		Rect2(455, 170, 50, 140),   # mid wall   (y 170 → 310)
		Rect2(455, 410, 50, 150),   # bot wall   (y 410 → 560)
	]
	for r in walls:
		_add_wall(r)

func _add_wall(rect: Rect2) -> void:
	var body  := StaticBody2D.new()
	body.collision_layer = 4   # layer 3 — river walls only
	body.position = rect.position + rect.size * 0.5
	var shape := CollisionShape2D.new()
	var rs    := RectangleShape2D.new()
	rs.size   = rect.size
	shape.shape = rs
	body.add_child(shape)
	add_child(body)
