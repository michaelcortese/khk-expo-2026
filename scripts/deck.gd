class_name Deck
extends RefCounted

# 8-card circular queue. hand = queue[0..3], next_card = queue[4].
# Playing a card removes it from its slot and appends it to the back —
# that's the entire cycle mechanic. No index arithmetic needed.

var hand: Array[CardData]   = []   # 4 visible/playable slots
var next_card: CardData     = null # 5th card shown as "coming up"
var _queue: Array[CardData] = []   # full 8-card queue

const DECK_SIZE: int = 8
const HAND_SIZE: int = 4

func setup(card_list: Array[CardData]) -> void:
	_queue.clear()
	# Fill to DECK_SIZE by repeating card_list
	var i: int = 0
	while _queue.size() < DECK_SIZE:
		_queue.append(card_list[i % card_list.size()])
		i += 1
	_queue.shuffle()
	_sync_hand()

# Play the card at slot_index (0-3).
# Played card goes to the back; next_card slides into the vacated slot.
# Returns the played CardData so the caller can spawn the troop.
func use_card(slot_index: int) -> CardData:
	var used: CardData = _queue[slot_index]
	_queue.remove_at(slot_index)
	_queue.append(used)
	_sync_hand()
	return used

func _sync_hand() -> void:
	hand.clear()
	for j in range(HAND_SIZE):
		hand.append(_queue[j])
	next_card = _queue[HAND_SIZE]
