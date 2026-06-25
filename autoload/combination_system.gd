extends Node


func start(root, top) -> void:
	var stack_ids = _collect_stack_ids(root)
	var hits: Array[StackRecipe] = []
	for r in RecipeRegistry.get_recipes(root.card_data.card_id):
		if _recipe_matches_stack(r, stack_ids) and EventBus.can_drop(r):
			hits.append(r)
	if hits.is_empty():
		for r in RecipeRegistry.get_recipes(top.card_data.card_id):
			if _recipe_matches_stack(r, stack_ids) and EventBus.can_drop(r):
				hits.append(r)
	if hits.is_empty():
		return
	_do_combine(root, top, hits)


func _do_combine(root, top, hits: Array[StackRecipe]) -> void:
	var chosen = _weighted_pick(hits)
	if chosen == null:
		return
	var base_pos = root.global_position + Vector2(180, 0)
	CardManager.combo_bottom = root
	CardManager.combo_top = top
	var bar = CardManager.BarScene.instantiate()
	bar.set_fill_color(Color(0.3, 0.8, 0.3))
	CardManager.combo_bar = bar

	if chosen.destroys_target:
		bar.attach_to(root, 3.0, func():
			EventBus.mark_drop_consumed(chosen)
			var container = EventBus.get_card_container()
			for child in root.get_children():
				if child is Control and child.is_in_group("cards"):
					child.reparent(container)
					child.global_position = root.global_position + Vector2(0, 80)
			CardManager.combo_bar = null
			CardManager.combo_bottom = null
			CardManager.combo_top = null
			root.queue_free()
		)
		return

	var data = chosen.result_card
	if data == null:
		return
	var count = randi_range(chosen.min_count, chosen.max_count)
	bar.attach_to(root, 3.0, func():
		EventBus.mark_drop_consumed(chosen)
		for i in range(count):
			var pos = base_pos + Vector2(i * 30, 0)
			var new_card = CardManager.spawn_card(data, pos)
			EventBus.card_combined.emit(root, top, new_card)
		bar.queue_free()
		CardManager.combo_bar = null
		CardManager.combo_bottom = null
		CardManager.combo_top = null
	)


static func _collect_stack_ids(root: Control) -> Array[String]:
	var ids: Array[String] = [root.card_data.card_id]
	var queue: Array = root.get_children()
	while queue.size() > 0:
		var child = queue.pop_front()
		if child is Control and child.is_in_group("cards"):
			ids.append(child.card_data.card_id)
			for gc in child.get_children():
				queue.append(gc)
	return ids


static func _recipe_matches_stack(r: StackRecipe, stack_ids: Array[String]) -> bool:
	for tc in r.target_cards:
		if tc == null or tc.card_id not in stack_ids:
			return false
	return true


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
