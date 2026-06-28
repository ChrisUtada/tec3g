extends Node


func start(root, top_card) -> void:
	if CardManager.dialogue_topic_card != null:
		return
	var config = root.card_data.dialogue_config
	if config == null:
		return
	CardManager.dialogue_topic_card = top_card
	CardManager.dialogue_root_card = root
	root.state = CardBase.CardState.IN_DIALOGUE
	if top_card:
		top_card.state = CardBase.CardState.IN_DIALOGUE

	# 进度条前置，避免瞬间弹窗
	var bar = CardManager.BarScene.instantiate()
	bar.set_fill_color(Color(0.3, 0.5, 1.0))
	bar.set_label("交谈中...")
	bar.attach_to(root, 1.5, func():
		bar.queue_free()
		# 进度条期间卡牌被拖走/断链 → 取消
		if CardManager.dialogue_topic_card == null:
			return
		if not is_instance_valid(root) or not is_instance_valid(top_card):
			CardManager.dialogue_topic_card = null
			return
		if not root.is_inside_tree() or not top_card.is_inside_tree():
			CardManager.dialogue_topic_card = null
			return
		EventBus.dialogue_requested.emit(config, root.card_data.card_name, top_card.card_data.card_id, root, top_card)
	)
