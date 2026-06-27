@tool
extends Control
class_name CardPlaceholder

@export var card_data: CardData

func _draw():
	if not Engine.is_editor_hint():
		return
	var r = Rect2(Vector2.ZERO, size)
	draw_rect(r, Color(0.3, 0.5, 0.8, 0.15))
	draw_rect(r, Color(0.3, 0.5, 0.8, 0.8), false, 2.0)
	var name_str = card_data.card_name if card_data else "（未设置）"
	draw_string(ThemeDB.fallback_font, Vector2(6, 16), name_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.8, 0.9, 1, 0.9))
	var type_str = "场景" if card_data and card_data.card_type == CardData.CardType.SCENE else "卡牌"
	draw_string(ThemeDB.fallback_font, Vector2(6, size.y - 6), type_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.7, 0.9, 0.6))

func _get_minimum_size() -> Vector2:
	return Vector2(160, 220)
