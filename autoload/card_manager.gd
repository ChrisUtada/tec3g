extends Node

var _combo_bar = null
var _combo_bottom = null
var _combo_top = null
var _bar_scene = preload("res://scenes/progress_bar_2d.tscn")

var _dialogue_topic_card = null


func _ready():
	EventBus.card_stacked.connect(_on_card_stacked)
	EventBus.spawn_card_requested.connect(_on_spawn_card_requested)
	EventBus.card_broken.connect(_on_card_broken)
	EventBus.dialogue_closed.connect(_on_dialogue_closed)


func _on_card_broken(card):
	if _combo_bar and card == _combo_top:
		_combo_bar.cancel()
		_combo_bar = null
		_combo_bottom = null
		_combo_top = null


func _on_card_stacked(bottom, top):
	if bottom.card_data == null or top.card_data == null:
		return

	if top.card_data.card_id == "LOGIC_observe" and bottom.card_data.multimedia_content:
		_do_observation(bottom, top)
		return

	var root = _get_stack_root(bottom)

	if root.card_data:
		var exp_config = SceneConfigRegistry.get_config(root.card_data.card_id)
		if exp_config:
			_try_exploration(root, exp_config)
			return

		if root.card_data.dialogue_config:
			_try_dialogue(root, top)
			return

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


func _try_exploration(root, config) -> void:
	if _combo_bar != null:
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

	_combo_bottom = root
	_combo_top = null
	_combo_bar = _bar_scene.instantiate()
	_combo_bar.set_fill_color(Color(0.3, 0.8, 0.3))
	_combo_bar.attach_to(root, config.explore_duration, func():
		_combo_bar.queue_free()
		_combo_bar = null
		_combo_bottom = null
		_on_exploration_complete(root, config, branch)
	)


func _branch_matches(branch, ingredient_ids: Array) -> bool:
	for req in branch.required_cards:
		var found = false
		for id in ingredient_ids:
			if req.accept_card_ids.has(id):
				found = true
				break
		if not found:
			return false
	return true


func _on_exploration_complete(root, config, branch) -> void:
	if config.rest_mode:
		for child in root.get_children():
			if child is Control and child.is_in_group("cards") and child.card_data:
				if "fatigue" in child.card_data.tags:
					child.queue_free()
		EventBus.exploration_requested.emit(config, {
			"branch_name": branch.branch_name,
			"drops": [],
			"fatigue": false,
			"rest": true
		})
		return

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
		EventBus.mark_drop_consumed(recipe)
		var data = recipe.result_card
		if data == null:
			continue
		var count = randi_range(recipe.min_count, recipe.max_count)
		for i in range(count):
			var pos = base_pos + Vector2(i * 30, 0)
			EventBus.spawn_card_requested.emit(data, pos)
			drops_info.append(data.card_name)

	var fatigue_spawned = false
	var fatigue_count = EventBus.get_cards_by_tag("fatigue").size()
	var drop_multiplier = max(0.0, 1.0 - fatigue_count * 0.2)
	if randf() < 0.25:
		EventBus.spawn_card_requested.emit(
			load("res://resources/cards/ITEM_fatigue.tres"),
			base_pos + Vector2(-60, 0)
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


func _try_dialogue(root, top_card) -> void:
	if _dialogue_topic_card != null:
		return
	var config = root.card_data.dialogue_config
	if config == null:
		return
	_dialogue_topic_card = top_card
	EventBus.dialogue_requested.emit(config, root.card_data.card_name, top_card.card_data.card_id)


func _on_dialogue_closed() -> void:
	if _dialogue_topic_card and is_instance_valid(_dialogue_topic_card) and _dialogue_topic_card.is_inside_tree():
		var container = EventBus.get_card_container()
		_dialogue_topic_card.reparent(container)
		_dialogue_topic_card.global_position = Vector2(randi_range(200, 600), randi_range(300, 600))
	_dialogue_topic_card = null


func _do_combine(root, top, hits: Array[StackRecipe]) -> void:
	var chosen = _weighted_pick(hits)
	if chosen == null:
		return
	var base_pos = root.global_position + Vector2(180, 0)
	_combo_bottom = root
	_combo_top = top
	_combo_bar = _bar_scene.instantiate()
	_combo_bar.set_fill_color(Color(0.3, 0.8, 0.3))

	if chosen.destroys_target:
		_combo_bar.attach_to(root, 3.0, func():
			EventBus.mark_drop_consumed(chosen)
			var container = EventBus.get_card_container()
			for child in root.get_children():
				if child is Control and child.is_in_group("cards"):
					child.reparent(container)
					child.global_position = root.global_position + Vector2(0, 80)
			_combo_bar = null
			_combo_bottom = null
			_combo_top = null
			root.queue_free()
		)
		return

	var data = chosen.result_card
	if data == null:
		return
	var count = randi_range(chosen.min_count, chosen.max_count)
	_combo_bar.attach_to(root, 3.0, func():
		EventBus.mark_drop_consumed(chosen)
		for i in range(count):
			var pos = base_pos + Vector2(i * 30, 0)
			var new_card = spawn_card(data, pos)
			EventBus.card_combined.emit(root, top, new_card)
		_combo_bar.queue_free()
		_combo_bar = null
		_combo_bottom = null
		_combo_top = null
	)


func _do_observation(target, observe_card) -> void:
	var bar = _bar_scene.instantiate()
	bar.set_fill_color(Color(0.5, 0.3, 1.0))
	_combo_bar = bar
	_combo_bottom = target
	_combo_top = observe_card
	bar.attach_to(target, 3.0, func():
		bar.queue_free()
		_combo_bar = null
		_combo_bottom = null
		_combo_top = null
		var panel = preload("res://scenes/multimedia_panel.tscn").instantiate()
		get_tree().current_scene.add_child(panel)
		panel.open(target.card_data.multimedia_content)
	)


static func _get_stack_root(card: Control) -> Control:
	var parent = card.get_parent()
	if parent is Control and parent.is_in_group("cards"):
		return _get_stack_root(parent)
	return card


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
