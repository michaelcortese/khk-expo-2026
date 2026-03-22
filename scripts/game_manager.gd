class_name GameManager
extends Node2D

const P1_KING_POS := Vector2(900, 240)
const P2_KING_POS := Vector2(60,  240)

const ELIXIR_RATE := 1.0 / 2.8
const ELIXIR_MAX  := 10.0

var p1_elixir: float = 5.0
var p2_elixir: float = 5.0

var p1_deck: Deck
var p2_deck: Deck

var _troop_scene: PackedScene
var _hud: HUD

func _ready() -> void:
	_troop_scene = load("res://troop.tscn")
	_setup_decks()
	_tag_towers()
	_setup_controllers()
	_setup_hud()
	_fit_camera_above_hud()

# ── Decks ─────────────────────────────────────────────────────────────────────
func _setup_decks() -> void:
	var cards := _make_cards()
	p1_deck = Deck.new()
	p1_deck.setup(cards)
	p2_deck = Deck.new()
	p2_deck.setup(cards)

func _make_cards() -> Array[CardData]:
	var list: Array[CardData] = []

	var knight := CardData.new()
	knight.card_id       = "knight"
	knight.display_name  = "Knight"
	knight.cost          = 3
	knight.max_hp        = 200
	knight.attack_damage = 30
	knight.attack_range  = 55.0
	knight.attack_speed  = 1.0
	knight.move_speed    = 80.0
	list.append(knight)

	var archer := CardData.new()
	archer.card_id       = "archer"
	archer.display_name  = "Archer"
	archer.cost          = 3
	archer.max_hp        = 130
	archer.attack_damage = 22
	archer.attack_range  = 145.0
	archer.attack_speed  = 1.2
	archer.move_speed    = 100.0
	list.append(archer)

	var giant := CardData.new()
	giant.card_id                = "giant"
	giant.display_name           = "Giant"
	giant.cost                   = 5
	giant.max_hp                 = 600
	giant.attack_damage          = 55
	giant.attack_range           = 55.0
	giant.attack_speed           = 0.7
	giant.move_speed             = 50.0
	giant.targets_structures_only = true
	list.append(giant)

	var barb := CardData.new()
	barb.card_id       = "barbarian"
	barb.display_name  = "Barbarian"
	barb.cost          = 5
	barb.max_hp        = 250
	barb.attack_damage = 65
	barb.attack_range  = 50.0
	barb.attack_speed  = 1.4
	barb.move_speed    = 95.0
	list.append(barb)

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
	_p1_controller.zone_max     = Vector2(490, 480)
	_p1_controller.cursor_color = Color(0.2, 0.6, 1.0, 0.9)
	add_child(_p1_controller)
	_p1_controller.card_played.connect(_on_card_played.bind(0))

	_p2_controller              = PlayerController.new()
	_p2_controller.name         = "P2Controller"
	_p2_controller.player_index = 1
	_p2_controller.joy_device   = 1
	_p2_controller.zone_min     = Vector2(510, 0)
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

# ── Win condition ─────────────────────────────────────────────────────────────
func _on_tower_destroyed(tower: Node) -> void:
	if _game_over:
		return
	if tower.get("is_king_tower"):
		var loser: int = tower.get("owner_player")
		_declare_winner(1 - loser)
	else:
		_expand_zone(tower)

func _expand_zone(tower: Node) -> void:
	# The player who destroyed this tower gets to deploy in the area it guarded.
	var owner: int     = tower.get("owner_player")
	var attacker_ctrl  := _p1_controller if owner == 1 else _p2_controller
	var top_lane: bool = tower.position.y < 240
	var y_min: float   = 0.0  if top_lane else 240.0
	var y_max: float   = 240.0 if top_lane else 480.0

	if owner == 1:
		# P2's tower died → P1 gets zone on P2's side
		attacker_ctrl.add_zone(Rect2(490, y_min, 250, y_max - y_min))
	else:
		# P1's tower died → P2 gets zone on P1's side
		attacker_ctrl.add_zone(Rect2(160, y_min, 330, y_max - y_min))

func _declare_winner(player_idx: int) -> void:
	_game_over = true
	_show_end_screen("PLAYER %d WINS!" % (player_idx + 1))

func _show_end_screen(msg: String) -> void:
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
	lbl.position = Vector2(0, -60)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 80)
	cl.add_child(lbl)

	var prompt := Label.new()
	prompt.text = "PRESS ANY BUTTON TO CONTINUE"
	prompt.set_anchors_preset(Control.PRESET_FULL_RECT)
	prompt.position = Vector2(0, 80)
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
	if not _awaiting_menu:
		return
	var pressed := false
	if event is InputEventKey:
		pressed = (event as InputEventKey).pressed and not (event as InputEventKey).echo
	elif event is InputEventJoypadButton:
		pressed = (event as InputEventJoypadButton).pressed
	if pressed:
		get_tree().change_scene_to_file("res://main_menu.tscn")

# ── Elixir tick ───────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if _game_over:
		return
	p1_elixir = minf(ELIXIR_MAX, p1_elixir + ELIXIR_RATE * delta)
	p2_elixir = minf(ELIXIR_MAX, p2_elixir + ELIXIR_RATE * delta)
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

	if player_idx == 0:
		p1_elixir -= float(card.cost)
	else:
		p2_elixir -= float(card.cost)

	deck.use_card(slot)
	_spawn_troop(card, player_idx, world_pos)

# ── Spawn ─────────────────────────────────────────────────────────────────────
func _spawn_troop(card: CardData, player_idx: int, pos: Vector2) -> void:
	var target := P1_KING_POS if player_idx == 0 else P2_KING_POS
	var troop  := _troop_scene.instantiate() as Node2D
	troop.position = pos
	add_child(troop)
	troop.call("init", card, player_idx, target)
