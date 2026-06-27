extends Node

var _style_box: StyleBoxFlat

@onready var _panel: Panel = $"../Panel"
@onready var _title_label: Label = $"../Title"
@onready var _desc_label: Label = $"../Description"
@onready var _type_label: Label = $"../TypeLabel"
@onready var _favor_label: Label = $"../FavorLabel"
@onready var _art_rect: TextureRect = $"../Art"

func refresh(data: CardData) -> void:
	if data == null:
		return
	if _style_box == null:
		_style_box = StyleBoxFlat.new()
	_style_box.bg_color = data.bg_color
	_style_box.set_border_width_all(2)
	_style_box.border_color = data.border_color
	_style_box.corner_radius_top_left = 8
	_style_box.corner_radius_top_right = 8
	_style_box.corner_radius_bottom_right = 8
	_style_box.corner_radius_bottom_left = 8
	_style_box.shadow_size = 6
	_style_box.shadow_color = Color(0, 0, 0, 0.3)
	_style_box.shadow_offset = Vector2(2, 2)
	_panel.add_theme_stylebox_override("panel", _style_box)
	_title_label.text = data.card_name
	_title_label.modulate = data.text_color
	_desc_label.text = data.description
	_type_label.text = _type_text(data.card_type, data.icon)
	_type_label.modulate = data.border_color
	if data.card_type == CardData.CardType.CHAR:
		_favor_label.show()
		_favor_label.text = "❤ %d/%d" % [data.favorability, data.max_favorability]
	else:
		_favor_label.hide()
	if _art_rect:
		if data.art:
			_art_rect.texture = data.art
			_art_rect.show()
		else:
			_art_rect.texture = null
			_art_rect.hide()

func update_favor_display(new_val: int, max_val: int) -> void:
	_favor_label.text = "❤ %d/%d" % [new_val, max_val]

static func _type_text(t: CardData.CardType, icon: String) -> String:
	var tag := ""
	match t:
		CardData.CardType.ITEM:  tag = "物品"
		CardData.CardType.CHAR:  tag = "人物"
		CardData.CardType.CLUE:  tag = "线索"
		CardData.CardType.LOGIC: tag = "指令"
		CardData.CardType.SCENE: tag = "场景"
		CardData.CardType.DEBUFF:tag = "状态"
	if icon.is_empty():
		return tag
	return "%s %s" % [icon, tag]
