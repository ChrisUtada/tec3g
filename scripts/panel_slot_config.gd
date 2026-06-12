class_name PanelSlotConfig extends Resource

@export var accept_card_ids: Array[String] = []
@export var accept_tags: Array[String] = []
@export var required: bool = true
@export var hint: String = "放入卡牌"

func matches(card) -> bool:
	if card == null or card.card_data == null:
		return false
	if not accept_card_ids.is_empty():
		if card.card_data.card_id not in accept_card_ids:
			return false
	for tag in accept_tags:
		if tag not in card.card_data.tags:
			return false
	return true
