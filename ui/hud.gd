extends CanvasLayer
class_name HUD

@onready var p1_elixir: ElixirBarWidget = $Root/Split/P1Panel/Layout/ElixirBarWidget
@onready var p2_elixir: ElixirBarWidget = $Root/Split/P2Panel/Layout/ElixirBarWidget

@onready var p1_hand: HBoxContainer = $Root/Split/P1Panel/Layout/HandBar
@onready var p2_hand: HBoxContainer = $Root/Split/P2Panel/Layout/HandBar

@onready var p1_next: TextureRect = $Root/Split/P1Panel/Layout/HandBar/NextCard/NextIcon
@onready var p2_next: TextureRect = $Root/Split/P2Panel/Layout/HandBar/NextCard/NextIcon

func set_p1_elixir(v: float) -> void:
	p1_elixir.set_elixir(v)

func set_p2_elixir(v: float) -> void:
	p2_elixir.set_elixir(v)

func set_p1_hand(ids: Array[String], names: Array[String] = [], costs: Array[int] = []) -> void:
	_set_hand(p1_hand, ids, names, costs)

func set_p2_hand(ids: Array[String], names: Array[String] = [], costs: Array[int] = []) -> void:
	_set_hand(p2_hand, ids, names, costs)

func set_p1_next(tex: Texture2D) -> void:
	p1_next.texture = tex

func set_p2_next(tex: Texture2D) -> void:
	p2_next.texture = tex

func _set_hand(hand_bar: HBoxContainer, ids: Array[String], names: Array[String], costs: Array[int]) -> void:
	# Expects first 4 children to be CardSlot instances; leaves NextCard as last child.
	for i in range(min(4, ids.size())):
		var slot := hand_bar.get_child(i) as CardSlot
		var n := names[i] if i < names.size() else ids[i]
		var c := costs[i] if i < costs.size() else 0
		slot.set_card(ids[i], n, c)
