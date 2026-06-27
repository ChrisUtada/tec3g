extends Node


func start(root, config) -> void:
	if CardManager.combo_bar != null:
		return
	var stack_ids = _collect_stack_ids(root)
	var ingredient_ids = stack_ids.duplicate()
	ingredient_ids.erase(root.card_data.card_id)

	var branch = null
	for b in config.branch_recipes:
		if _branch_matches(b, ingredient_ids):
			branch = b
			break
	if branch == null:
		return

	CardManager.combo_bottom = root
	CardManager.combo_top = null
	CardManager.exploring = true
	var bar = CardManager.BarScene.instantiate()
	bar.set_fill_color(Color(0.3, 0.8, 0.3))
	CardManager.combo_bar = bar
	bar.attach_to(root, config.explore_duration, func():
		bar.queue_free()
		CardManager.combo_bar = null
		_on_exploration_complete(root, config, branch)
	)


func _on_exploration_complete(root, config, branch) -> void:
	if config.rest_mode:
		_process_rest(root, config, branch)
		return

	CardManager.exploring = false
	CardManager.combo_bottom = null

	var base_pos = root.global_position + Vector2(180, 0)
	var drops_info = []

	if branch.add_favorability > 0:
		for child in root.get_children():
			if child is Control and child.is_in_group("cards") and child.card_data:
				if child.card_data.card_type == CardData.CardType.CHAR:
					var old = child.card_data.favorability
					child.card_data.favorability = mini(old + branch.add_favorability, child.card_data.max_favorability)
					EventBus.favorability_changed.emit(child.card_data.card_id, old, child.card_data.favorability, branch.add_favorability)
					break

	for recipe in branch.result_recipes:
		if not EventBus.can_drop(recipe):
			continue
		var data = recipe.result_card
		if data == null:
			continue
		if recipe.unique and EventBus.has_dropped_unique(data.card_id):
			continue
		if recipe.no_duplicate and EventBus.has_card_on_board(data.card_id):
			continue
		EventBus.mark_drop_consumed(recipe)
		var count = randi_range(recipe.min_count, recipe.max_count)
		for i in range(count):
			var pos = base_pos + Vector2(i * 30, 0)
			CardManager.spawn_card(data, pos, root)
			drops_info.append(data.card_name)

	var fatigue_spawned = false
	if randf() < 0.25:
		CardManager.spawn_card(
			load("res://resources/cards/ITEM_fatigue.tres"),
			base_pos + Vector2(-60, 0),
			root
		)
		fatigue_spawned = true

	var container = EventBus.get_card_container()
	for child in root.get_children():
		if child is Control and child.is_in_group("cards"):
			child.reparent(container)
			child.global_position = root.global_position + Vector2(randi_range(-60, 60), 80 + randi_range(-20, 20))

	EventBus.exploration_requested.emit(config, {
		"branch_name": branch.branch_name,
		"drops": drops_info,
		"fatigue": fatigue_spawned
	})


func _process_rest(root, config, branch) -> void:
	var fatigue_count = 0
	for child in root.get_children():
		if child is Control and child.is_in_group("cards") and child.card_data and child.card_data.fatigue_trigger:
			fatigue_count += 1
	if fatigue_count == 0:
		return
	for child in root.get_children():
		if child is Control and child.is_in_group("cards") and child.card_data and child.card_data.fatigue_trigger:
			child.queue_free()
			break
	if fatigue_count > 1:
		var bar = CardManager.BarScene.instantiate()
		bar.set_fill_color(Color(0.3, 0.8, 0.3))
		CardManager.combo_bar = bar
		bar.attach_to(root, config.explore_duration, func():
			bar.queue_free()
			CardManager.combo_bar = null
			_process_rest(root, config, branch)
		)
		return
	CardManager.exploring = false
	CardManager.combo_bottom = null
	EventBus.exploration_requested.emit(config, {
		"branch_name": branch.branch_name,
		"drops": [],
		"fatigue": false,
		"rest": true
	})


static func _branch_matches(branch, ingredient_ids: Array) -> bool:
	if ingredient_ids.size() != branch.required_cards.size():
		return false
	for req in branch.required_cards:
		var found = false
		for id in ingredient_ids:
			if req.accept_card_ids.has(id):
				found = true
				break
		if not found:
			return false
	return true


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
