extends CanvasLayer
class_name HUD

# ---------------------------------------------------------------------------
# Node references — paths match HUD_segmented_hand.tscn exactly
# ---------------------------------------------------------------------------
@onready var p1_elixir: ElixirBarWidget = \
	$Root/BottomBar/P1Panel/P1VBox/P1ElixirBar
@onready var p2_elixir: ElixirBarWidget = \
	$Root/BottomBar/P2Panel/P2VBox/P2ElixirBar

@onready var p1_hand: HBoxContainer = \
	$Root/BottomBar/P1Panel/P1VBox/P1Cards
@onready var p2_hand: HBoxContainer = \
	$Root/BottomBar/P2Panel/P2VBox/P2Cards

@onready var timer_label: Label = \
	$Root/TimerBar/TimerLabel
@onready var double_elixir_badge: Control = \
	$Root/BottomBar/DoubleElixirBadge

# ---------------------------------------------------------------------------
# Signal handlers (connected from GameManager)
# ---------------------------------------------------------------------------
func _on_timer_updated(time_left: float) -> void:
	var mins := int(time_left) / 60
	var secs := int(time_left) % 60
	timer_label.text = "%d:%02d" % [mins, secs]

func _on_double_elixir_started() -> void:
	double_elixir_badge.visible = true
	p1_elixir.set_double_elixir_mode(true)
	p2_elixir.set_double_elixir_mode(true)

# ---------------------------------------------------------------------------
# Called by GameManager each time a card is played
# ---------------------------------------------------------------------------
func set_p1_elixir(v: float) -> void:
	p1_elixir.set_elixir(v)

func set_p2_elixir(v: float) -> void:
	p2_elixir.set_elixir(v)

## ids / names / costs may contain 4 (hand) or 5 (hand + next) entries.
## Child order in P1Cards / P2Cards: Card1, Card2, Card3, Card4, UpNext.
func set_p1_hand(ids: Array[String], names: Array[String] = [], costs: Array[int] = []) -> void:
	_set_hand(p1_hand, ids, names, costs)

func set_p2_hand(ids: Array[String], names: Array[String] = [], costs: Array[int] = []) -> void:
	_set_hand(p2_hand, ids, names, costs)

func _set_hand(
		hand_bar: HBoxContainer,
		ids:   Array[String],
		names: Array[String],
		costs: Array[int]) -> void:
	# Slots 0-3 are the playable cards; slot 4 is the UpNext preview.
	for i in range(mini(5, ids.size())):
		var slot := hand_bar.get_child(i) as CardSlot
		if slot == null:
			continue
		var n := names[i] if i < names.size() else ids[i]
		var c := costs[i] if i < costs.size() else 0
		slot.set_card(ids[i], n, c)
