extends Node


func start(root, top_card) -> void:
	if CardManager.dialogue_topic_card != null:
		return
	var config = root.card_data.dialogue_config
	if config == null:
		return
	CardManager.dialogue_topic_card = top_card
	EventBus.dialogue_requested.emit(config, root.card_data.card_name, top_card.card_data.card_id)
