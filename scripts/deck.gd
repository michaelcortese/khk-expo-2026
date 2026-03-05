class_name Deck
extends RefCounted

## Manages one player's 8-card deck. Keeps a 4-card hand visible + next card.

var _cards: Array[CardData] = []
var hand: Array[CardData] = []   # 4 visible slots
var next_card: CardData = null
var _next_idx: int = 0

func setup(card_list: Array[CardData]) -> void:
	_cards = card_list.duplicate()
	# Ensure we have enough cards to fill hand + next
	while _cards.size() < 5:
		_cards.append_array(card_list)
	hand.clear()
	for i in range(4):
		hand.append(_cards[i])
	next_card = _cards[4]
	_next_idx = 5

## Returns the card that was played. Rotates next_card into the used slot.
func use_card(slot_index: int) -> CardData:
	var used: CardData = hand[slot_index]
	hand[slot_index] = next_card
	next_card = _cards[_next_idx % _cards.size()]
	_next_idx = (_next_idx + 1) % _cards.size()
	return used
