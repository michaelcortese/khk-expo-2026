class_name Deck
extends RefCounted

var hand: Array[CardData]      = []   # 4 visible slots
var next_card: CardData        = null
var _cards: Array[CardData]    = []
var _next_idx: int             = 0

func setup(card_list: Array[CardData]) -> void:
	_cards = card_list.duplicate()
	while _cards.size() < 5:
		_cards.append_array(card_list)
	hand.clear()
	for i in range(4):
		hand.append(_cards[i])
	next_card = _cards[4]
	_next_idx = 5

## Play a card from slot_index. Returns the card that was played.
func use_card(slot_index: int) -> CardData:
	var used: CardData   = hand[slot_index]
	hand[slot_index]     = next_card
	next_card            = _cards[_next_idx % _cards.size()]
	_next_idx            = (_next_idx + 1) % _cards.size()
	return used
