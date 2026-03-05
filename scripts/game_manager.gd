class_name GameManager
extends Node2D

## Main orchestrator for KHK Royale.
## Attach to the root Game node in game.tscn.

# ---------------------------------------------------------------------------
# Signals (cross-system communication)
# ---------------------------------------------------------------------------
signal timer_updated(time_left: float)
signal double_elixir_started()

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------
@export var game_duration: float    = 180.0   # 3:00
@export var p1_joy_device: int      = 0
@export var p2_joy_device: int      = 1

# ---------------------------------------------------------------------------
# Elixir constants
# ---------------------------------------------------------------------------
const ELIXIR_RATE_NORMAL := 1.0 / 2.8   # +1 per 2.8 s
const ELIXIR_RATE_DOUBLE := 1.0 / 1.4   # +1 per 1.4 s (double-elixir mode)

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
@onready var hud: HUD = $HUD

var p1_elixir: float  = 0.0
var p2_elixir: float  = 0.0
var double_elixir: bool = false
var game_timer: float = 0.0
var game_over: bool   = false
var p1_crowns: int    = 0
var p2_crowns: int    = 0

var p1_deck: Deck
var p2_deck: Deck
var p1_controller: PlayerController
var p2_controller: PlayerController

var _troop_scene: PackedScene

var _p1_king: Tower
var _p1_princess1: Tower
var _p1_princess2: Tower
var _p2_king: Tower
var _p2_princess1: Tower
var _p2_princess2: Tower

# ---------------------------------------------------------------------------
# Init
# ---------------------------------------------------------------------------
func _ready() -> void:
	_troop_scene = preload("res://troop.tscn")
	_setup_towers()
	_setup_decks()
	_setup_controllers()
	_update_hud_hands()

	# Wire signals → HUD
	timer_updated.connect(hud._on_timer_updated)
	double_elixir_started.connect(hud._on_double_elixir_started)

	# Show initial timer display
	timer_updated.emit(game_duration)

# ---------------------------------------------------------------------------
# Towers
# ---------------------------------------------------------------------------
func _setup_towers() -> void:
	_p1_king      = get_node_or_null("King_Tower_P1")      as Tower
	_p1_princess1 = get_node_or_null("Princess_Tower1_P1") as Tower
	_p1_princess2 = get_node_or_null("Princess_Tower2_P1") as Tower
	_p2_king      = get_node_or_null("King_Tower_P2")      as Tower
	_p2_princess1 = get_node_or_null("Princess_Tower1_P2") as Tower
	_p2_princess2 = get_node_or_null("Princess_Tower2_P2") as Tower

	_init_tower(_p1_king,      0, true,  2400)
	_init_tower(_p1_princess1, 0, false, 1400)
	_init_tower(_p1_princess2, 0, false, 1400)
	_init_tower(_p2_king,      1, true,  2400)
	_init_tower(_p2_princess1, 1, false, 1400)
	_init_tower(_p2_princess2, 1, false, 1400)

func _init_tower(tower: Tower, player_idx: int, is_king: bool, hp: int) -> void:
	if tower == null:
		return
	tower.owner_player = player_idx
	tower.is_king_tower = is_king
	tower.max_hp        = hp
	tower.add_to_group("towers")
	tower.destroyed.connect(_on_tower_destroyed.bind(tower, player_idx, is_king))

# ---------------------------------------------------------------------------
# Decks
# ---------------------------------------------------------------------------
func _setup_decks() -> void:
	var cards := _make_default_cards()
	p1_deck = Deck.new()
	p1_deck.setup(cards)
	p2_deck = Deck.new()
	p2_deck.setup(cards)

func _make_default_cards() -> Array[CardData]:
	var list: Array[CardData] = []

	var knight := CardData.new()
	knight.card_id        = "knight"
	knight.display_name   = "Knight"
	knight.cost           = 3
	knight.troop_type     = CardData.TroopType.KNIGHT
	knight.max_hp         = 300
	knight.attack_damage  = 35
	knight.attack_range   = 55.0
	knight.attack_speed   = 1.0
	knight.move_speed     = 80.0
	list.append(knight)

	var archer := CardData.new()
	archer.card_id        = "archer"
	archer.display_name   = "Archer"
	archer.cost           = 3
	archer.troop_type     = CardData.TroopType.ARCHER
	archer.max_hp         = 130
	archer.attack_damage  = 22
	archer.attack_range   = 145.0
	archer.attack_speed   = 1.2
	archer.move_speed     = 100.0
	list.append(archer)

	var giant := CardData.new()
	giant.card_id                = "giant"
	giant.display_name           = "Giant"
	giant.cost                   = 5
	giant.troop_type             = CardData.TroopType.GIANT
	giant.max_hp                 = 600
	giant.attack_damage          = 55
	giant.attack_range           = 55.0
	giant.attack_speed           = 0.7
	giant.move_speed             = 50.0
	giant.targets_structures_only = true
	list.append(giant)

	var barb := CardData.new()
	barb.card_id        = "barbarian"
	barb.display_name   = "Barbarian"
	barb.cost           = 5
	barb.troop_type     = CardData.TroopType.BARBARIAN
	barb.max_hp         = 250
	barb.attack_damage  = 65
	barb.attack_range   = 50.0
	barb.attack_speed   = 1.4
	barb.move_speed     = 95.0
	list.append(barb)

	return list

# ---------------------------------------------------------------------------
# Controllers
# ---------------------------------------------------------------------------
func _setup_controllers() -> void:
	p1_controller = PlayerController.new()
	p1_controller.name         = "P1Controller"
	p1_controller.player_index = 0
	p1_controller.joy_device   = p1_joy_device
	p1_controller.cursor_speed = 350.0
	p1_controller.zone_min     = Vector2(30,  0)
	p1_controller.zone_max     = Vector2(460, 520)
	p1_controller.cursor_color = Color(0.0, 0.85, 1.0, 0.85)
	add_child(p1_controller)
	p1_controller.card_played.connect(_on_p1_card_played)

	p2_controller = PlayerController.new()
	p2_controller.name         = "P2Controller"
	p2_controller.player_index = 1
	p2_controller.joy_device   = p2_joy_device
	p2_controller.cursor_speed = 350.0
	p2_controller.zone_min     = Vector2(500, 0)
	p2_controller.zone_max     = Vector2(960, 520)
	p2_controller.cursor_color = Color(1.0, 0.45, 0.10, 0.85)
	add_child(p2_controller)
	p2_controller.card_played.connect(_on_p2_card_played)

# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------
func _process(delta: float) -> void:
	if game_over:
		return

	game_timer += delta
	var time_left := maxf(0.0, game_duration - game_timer)
	timer_updated.emit(time_left)

	# Trigger double-elixir at 1:00 remaining
	if not double_elixir and time_left <= 60.0:
		double_elixir = true
		double_elixir_started.emit()

	var rate := ELIXIR_RATE_DOUBLE if double_elixir else ELIXIR_RATE_NORMAL
	p1_elixir = minf(10.0, p1_elixir + rate * delta)
	p2_elixir = minf(10.0, p2_elixir + rate * delta)

	hud.set_p1_elixir(p1_elixir)
	hud.set_p2_elixir(p2_elixir)

	if game_timer >= game_duration:
		_end_game()

# ---------------------------------------------------------------------------
# Card deployment
# ---------------------------------------------------------------------------
func _on_p1_card_played(slot_index: int, world_pos: Vector2) -> void:
	var card: CardData = p1_deck.hand[slot_index]
	if p1_elixir < float(card.cost):
		return
	p1_elixir -= float(card.cost)
	p1_deck.use_card(slot_index)
	_spawn_troop(card, 0, world_pos)
	_update_hud_hands()

func _on_p2_card_played(slot_index: int, world_pos: Vector2) -> void:
	var card: CardData = p2_deck.hand[slot_index]
	if p2_elixir < float(card.cost):
		return
	p2_elixir -= float(card.cost)
	p2_deck.use_card(slot_index)
	_spawn_troop(card, 1, world_pos)
	_update_hud_hands()

func _spawn_troop(card: CardData, player_idx: int, pos: Vector2) -> void:
	var enemy_king_pos: Vector2
	if player_idx == 0:
		enemy_king_pos = _p2_king.position if _p2_king else Vector2(910, 207)
	else:
		enemy_king_pos = _p1_king.position if _p1_king else Vector2(-20, 215)

	var troop: TroopUnit = _troop_scene.instantiate() as TroopUnit
	troop.init(card, player_idx, enemy_king_pos)
	troop.position = pos
	add_child(troop)

func _update_hud_hands() -> void:
	# Pass 4 hand cards + 1 next_card (5 total) to each player's HUD slot row.
	var ids:   Array[String] = []
	var names: Array[String] = []
	var costs: Array[int]    = []

	for c in p1_deck.hand:
		ids.append(c.card_id);  names.append(c.display_name);  costs.append(c.cost)
	if p1_deck.next_card:
		ids.append(p1_deck.next_card.card_id)
		names.append(p1_deck.next_card.display_name)
		costs.append(p1_deck.next_card.cost)
	hud.set_p1_hand(ids, names, costs)

	ids.clear();  names.clear();  costs.clear()
	for c in p2_deck.hand:
		ids.append(c.card_id);  names.append(c.display_name);  costs.append(c.cost)
	if p2_deck.next_card:
		ids.append(p2_deck.next_card.card_id)
		names.append(p2_deck.next_card.display_name)
		costs.append(p2_deck.next_card.cost)
	hud.set_p2_hand(ids, names, costs)

# ---------------------------------------------------------------------------
# Win / loss
# ---------------------------------------------------------------------------
func _on_tower_destroyed(_tower: Tower, player_idx: int, is_king: bool) -> void:
	if is_king:
		_declare_winner(1 - player_idx)
	else:
		if player_idx == 0:
			p2_crowns += 1
		else:
			p1_crowns += 1

func _end_game() -> void:
	game_over = true
	if p1_crowns > p2_crowns:
		_declare_winner(0)
	elif p2_crowns > p1_crowns:
		_declare_winner(1)
	else:
		_show_end_message("DRAW!")

func _declare_winner(player_idx: int) -> void:
	game_over = true
	_show_end_message("PLAYER %d WINS!" % (player_idx + 1))

func _show_end_message(msg: String) -> void:
	var cl := CanvasLayer.new()
	cl.layer = 20
	add_child(cl)

	var panel := ColorRect.new()
	panel.color = Color(0.0, 0.0, 0.0, 0.65)
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	cl.add_child(panel)

	var label := Label.new()
	label.text = msg
	label.add_theme_font_size_override("font_size", 80)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	cl.add_child(label)
