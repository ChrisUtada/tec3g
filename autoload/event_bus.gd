extends Node

# ── Service Locator ──
var _card_container = null

func set_card_container(c) -> void:
	_card_container = c

func get_card_container():
	return _card_container

var _staging_bar = null

func set_staging_bar(b) -> void:
	_staging_bar = b

func get_staging_bar():
	return _staging_bar


# ── Card Events ──
signal card_created(card)
signal card_drag_started(card)
signal card_drag_ended(card)
signal card_stacked(bottom, top)
signal card_broken(card)
signal card_combined(bottom, top, result)


# ── Card Registry ──
var _cards_by_id: Dictionary = {}  # card_id -> Array of cards
var _all_cards: Array = []

func register_card(card) -> void:
	if card.card_data and not card.card_data.card_id.is_empty():
		var id = card.card_data.card_id
		if not _cards_by_id.has(id):
			_cards_by_id[id] = []
		_cards_by_id[id].append(card)
	_all_cards.append(card)

func unregister_card(card) -> void:
	if card.card_data and not card.card_data.card_id.is_empty():
		var id = card.card_data.card_id
		var cards = _cards_by_id.get(id)
		if cards is Array:
			cards.erase(card)
			if cards.is_empty():
				_cards_by_id.erase(id)
	_all_cards.erase(card)

func get_card_by_id(id: String):
	var cards = _cards_by_id.get(id)
	if cards is Array and cards.size() > 0:
		return cards[-1]
	return null

func get_all_cards_by_id(id: String) -> Array:
	var cards = _cards_by_id.get(id)
	if cards is Array:
		return cards.duplicate()
	return []

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

func has_card_on_board(card_id: String) -> bool:
	var cards = _cards_by_id.get(card_id)
	return cards is Array and cards.size() > 0


# ── Drop Consumption ──
var _drop_remaining: Dictionary = {}  # result_id -> 剩余次数

func can_drop(recipe) -> bool:
	var max = recipe.max_drops
	if max == 0:
		return true
	var rid = recipe.result_card.card_id if recipe.result_card else ""
	if rid.is_empty():
		return true
	if not _drop_remaining.has(rid):
		_drop_remaining[rid] = max
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
signal dialogue_requested(config, character_name, topic_card_id, root_card, topic_card)
signal dialogue_closed()


# ── Spawn Request ──
signal spawn_card_requested(data, position)


# ── Corruption ──
signal corruption_triggered(card_id)


# ── Favorability ──
signal favorability_changed(card_id, old_value, new_value, delta)


# ── Scene Desktop ──
signal scene_desktop_entered(card_data)
signal scene_desktop_exited()


# ── Staging ──
signal staging_arrange_requested(dropped_card, was_in_staging)
