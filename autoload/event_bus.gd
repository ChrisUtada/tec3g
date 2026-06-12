extends Node

# ── Service Locator ──
var _drop_handler = null
var _card_container = null

func register_drop_handler(h) -> void:
	_drop_handler = h

func unregister_drop_handler() -> void:
	_drop_handler = null

func get_drop_handler():
	return _drop_handler

func set_card_container(c) -> void:
	_card_container = c

func get_card_container():
	return _card_container


# ── Card Events ──
signal card_created(card)
signal card_drag_started(card)
signal card_drag_ended(card)
signal card_stacked(bottom, top)
signal card_broken(card)
signal card_combined(bottom, top, result)


# ── Exploration Events ──
signal exploration_requested(config)
signal card_placed_in_slot(slot, card)
signal card_removed_from_slot(slot, card)
signal exploration_started()
signal exploration_completed()
signal exploration_closed()


# ── Card Registry ──
var _cards_by_id: Dictionary = {}
var _all_cards: Array = []

func register_card(card) -> void:
	if card.card_data and not card.card_data.card_id.is_empty():
		_cards_by_id[card.card_data.card_id] = card
	_all_cards.append(card)

func unregister_card(card) -> void:
	if card.card_data and not card.card_data.card_id.is_empty():
		_cards_by_id.erase(card.card_data.card_id)
	_all_cards.erase(card)

func get_card_by_id(id: String):
	return _cards_by_id.get(id)

func get_cards_by_tag(tag: String) -> Array:
	var result: Array = []
	var i := 0
	while i < _all_cards.size():
		var card = _all_cards[i]
		if not is_instance_valid(card):
			_all_cards.remove_at(i)
			continue
		if tag in card.card_data.tags:
			result.append(card)
		i += 1
	return result

func get_all_cards() -> Array:
	var result: Array = []
	for card in _all_cards:
		if is_instance_valid(card):
			result.append(card)
	return result


# ── Drop Consumption ──
var _drop_remaining: Dictionary = {}  # result_id -> 剩余次数

func can_drop(recipe) -> bool:
	if recipe.max_drops == 0:
		return true
	var rid = recipe.result_card.card_id if recipe.result_card else ""
	if rid.is_empty():
		return true
	if not _drop_remaining.has(rid):
		_drop_remaining[rid] = recipe.max_drops
	return _drop_remaining[rid] > 0

func mark_drop_consumed(recipe) -> void:
	if recipe.max_drops == 0:
		return
	var rid = recipe.result_card.card_id if recipe.result_card else ""
	if rid.is_empty():
		return
	if not _drop_remaining.has(rid):
		_drop_remaining[rid] = recipe.max_drops
	_drop_remaining[rid] -= 1


# ── Dialogue Events ──
signal dialogue_requested(config, character_name)
signal dialogue_closed()


# ── Spawn Request ──
signal spawn_card_requested(data, position)
