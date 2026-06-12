extends Node

var _combo_bar = null
var _combo_bottom = null
var _combo_top = null
var _bar_scene = preload("res://scenes/progress_bar_2d.tscn")

func _ready():
	EventBus.card_stacked.connect(_on_card_stacked)
	EventBus.spawn_card_requested.connect(_on_spawn_card_requested)
	EventBus.card_broken.connect(_on_card_broken)

func _on_card_broken(card):
	if _combo_bar and card == _combo_top:
		_combo_bar.cancel()
		_combo_bar = null
		_combo_bottom = null
		_combo_top = null

func _on_card_stacked(bottom, top):
	if bottom.card_data == null or top.card_data == null:
		return
	var hits: Array[StackRecipe] = []
	for r in bottom.card_data.recipes:
		if r.target_card and r.target_card.card_id == top.card_data.card_id and EventBus.can_drop(r):
			hits.append(r)
	if hits.is_empty():
		for r in top.card_data.recipes:
			if r.target_card and r.target_card.card_id == bottom.card_data.card_id and EventBus.can_drop(r):
				hits.append(r)
	if hits.is_empty():
		return
	_do_combine(bottom, top, hits)

func _do_combine(bottom, top, hits: Array[StackRecipe]) -> void:
	var chosen = _weighted_pick(hits)
	if chosen == null:
		return
	var data = chosen.result_card
	if data == null:
		return
	var count = randi_range(chosen.min_count, chosen.max_count)
	var base_pos = bottom.global_position + Vector2(180, 0)
	_combo_bottom = bottom
	_combo_top = top
	_combo_bar = _bar_scene.instantiate()
	_combo_bar.set_fill_color(Color(0.3, 0.8, 0.3))
	_combo_bar.attach_to(bottom, 3.0, func():
		EventBus.mark_drop_consumed(chosen)
		for i in range(count):
			var pos = base_pos + Vector2(i * 30, 0)
			var new_card = spawn_card(data, pos)
			EventBus.card_combined.emit(bottom, top, new_card)
		_combo_bar.queue_free()
		_combo_bar = null
		_combo_bottom = null
		_combo_top = null
	)

static func _weighted_pick(hits: Array[StackRecipe]) -> StackRecipe:
	if hits.is_empty():
		return null
	if hits.size() == 1:
		return hits[0]
	var total := 0.0
	for r in hits:
		total += r.weight
	var roll := randf_range(0.0, total)
	var cumulative := 0.0
	for r in hits:
		cumulative += r.weight
		if roll <= cumulative:
			return r
	return hits[-1]

func _on_spawn_card_requested(data: CardData, global_position: Vector2) -> void:
	spawn_card(data, global_position)

func spawn_card(data: CardData, global_position: Vector2) -> Control:
	var scene = preload("res://scenes/cards/card_base.tscn")
	var card = scene.instantiate()
	card.setup(data)
	var container = EventBus.get_card_container()
	container.add_child(card)
	card.global_position = global_position
	EventBus.register_card(card)
	EventBus.card_created.emit(card)
	return card
