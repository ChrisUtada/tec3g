extends Node


func start(root, top) -> bool:
	var stack_ids = CardManager.collect_stack_ids(root)
	var stack_cards = _collect_stack_cards(root)
	var hits: Array[StackRecipe] = []
	for r in RecipeRegistry.get_recipes(root.card_data.card_id):
		if r.top_only:
			continue
		if _recipe_matches_stack(r, stack_ids, stack_cards) and EventBus.can_drop(r):
			hits.append(r)
	if hits.is_empty():
		for r in RecipeRegistry.get_recipes(top.card_data.card_id):
			if _recipe_matches_stack(r, stack_ids, stack_cards) and EventBus.can_drop(r):
				hits.append(r)
	if hits.is_empty():
		return false
	_do_combine(root, top, hits, stack_cards)
	return true


func _do_combine(root, top, hits: Array[StackRecipe], stack_cards: Array) -> void:
	var chosen = _weighted_pick(hits)
	if chosen == null:
		return
	var base_pos = root.global_position + Vector2(180, 0)
	CardManager.combo_bottom = root
	CardManager.combo_top = top
	var bar = CardManager.BarScene.instantiate()
	bar.set_fill_color(Color(0.3, 0.8, 0.3))
	bar.set_label("组合中...")
	CardManager.combo_bar = bar

	bar.attach_to(root, 3.0, func():
		# 卡牌可能被外部机制销毁（如腐化计时器）→ 跳过合成
		if not is_instance_valid(root) or not is_instance_valid(top):
			CardManager.combo_bar = null
			CardManager.combo_bottom = null
			CardManager.combo_top = null
			return
		EventBus.mark_drop_consumed(chosen)
		var container = EventBus.get_card_container()

		# ── Primary Action ──
		if chosen.consumes_top:
			# 消耗顶层：top 销毁，root 保留
			if is_instance_valid(top):
				for child in top.get_children():
					if child is Control and child.is_in_group("cards"):
						child.reparent(container)
						child.global_position = root.global_position + Vector2(randi_range(-40, 40), 80 + randi_range(-20, 20))
				top.queue_free()
		elif chosen.destroys_target:
			# 销毁目标：root 销毁，子卡散落
			for child in root.get_children():
				if child is Control and child.is_in_group("cards"):
					child.reparent(container)
					child.global_position = root.global_position + Vector2(0, 80)
			root.queue_free()

		# ── Spawn Result ──
		if chosen.result_card:
			var count = randi_range(chosen.min_count, chosen.max_count)
			for i in range(count):
				var pos = base_pos + Vector2(i * 30, 0)
				var new_card = CardManager.spawn_card(chosen.result_card, pos)
				if new_card:
					EventBus.card_combined.emit(root, top, new_card)

		# ── Favorability Side Effect ──
		if chosen.add_favorability != 0:
			_apply_favorability(stack_cards, chosen.add_favorability)

		bar.queue_free()
		CardManager.combo_bar = null
		CardManager.combo_bottom = null
		CardManager.combo_top = null
	)


# ── Recipe Matching ──

static func _recipe_matches_stack(r: StackRecipe, stack_ids: Array[String], stack_cards: Array) -> bool:
	# 严格匹配：堆叠总数必须恰好等于 root + target_cards，多一张都不行
	if stack_ids.size() != 1 + r.target_cards.size():
		return false
	# 每个 target card_id 必须在堆叠中出现足够次数
	var expected: Dictionary = {}
	for tc in r.target_cards:
		if tc == null:
			return false
		expected[tc.card_id] = expected.get(tc.card_id, 0) + 1
	for card_id in expected:
		if stack_ids.count(card_id) < expected[card_id]:
			return false
	# Tag condition: at least one card in the stack must carry each required tag
	for tag in r.require_tags:
		var found = false
		for card in stack_cards:
			if card.card_data and tag in card.card_data.tags:
				found = true
				break
		if not found:
			return false
	# Favorability condition: a CHAR card in the stack must meet the minimum
	if r.require_favorability_min > 0:
		var char_card = _find_char_card_in(stack_cards)
		if not char_card or char_card.card_data.favorability < r.require_favorability_min:
			return false
	return true


# ── Stack Traversal ──

static func _collect_stack_cards(root: Control) -> Array:
	var cards: Array = []
	var stack: Array = [root]
	while stack.size() > 0:
		var c = stack.pop_back()
		if c is Control and c.is_in_group("cards"):
			cards.append(c)
		for child in c.get_children():
			stack.append(child)
	return cards


static func _find_char_card_in(cards: Array):
	for card in cards:
		if card is Control and card.card_data and card.card_data.card_type == CardData.CardType.CHAR:
			return card
	return null


# ── Weighted Random ──

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


# ── Favorability ──

static func _apply_favorability(stack_cards: Array, delta: int) -> void:
	var char_card = _find_char_card_in(stack_cards)
	if not char_card:
		return
	var old = char_card.card_data.favorability
	var new_val = clampi(old + delta, 0, char_card.card_data.max_favorability)
	if new_val != old:
		char_card.card_data.favorability = new_val
		EventBus.favorability_changed.emit(char_card.card_data.card_id, old, new_val, delta)
