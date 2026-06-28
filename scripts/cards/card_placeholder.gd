@tool
extends Control
class_name CardPlaceholder

enum PlaceholderZone { BOARD, STAGING }

@export var card_data: CardData:
	set(v):
		card_data = v
		queue_redraw()

@export var zone: PlaceholderZone = PlaceholderZone.BOARD:
	set(v):
		zone = v
		queue_redraw()


func _draw():
	if not Engine.is_editor_hint():
		return
	var r = Rect2(Vector2.ZERO, size)
	var is_board = (zone == PlaceholderZone.BOARD)
	var fill = Color(0.3, 0.5, 0.8, 0.15) if is_board else Color(0.2, 0.5, 0.3, 0.15)
	var stroke = Color(0.3, 0.5, 0.8, 0.8) if is_board else Color(0.2, 0.6, 0.35, 0.8)
	draw_rect(r, fill)
	draw_rect(r, stroke, false, 2.0)
	var name_str = card_data.card_name if card_data else "（未设置）"
	draw_string(ThemeDB.fallback_font, Vector2(6, 16), name_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.8, 0.9, 1, 0.9))
	var bottom_str: String
	if is_board:
		bottom_str = "BOARD (%d, %d)" % [int(position.x), int(position.y)]
	else:
		bottom_str = "STAGING"
	draw_string(ThemeDB.fallback_font, Vector2(6, size.y - 6), bottom_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.7, 0.9, 0.6))


func _get_minimum_size() -> Vector2:
	return Vector2(160, 220)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not card_data:
		warnings.append("CardPlaceholder has no card_data assigned.")
	return warnings
