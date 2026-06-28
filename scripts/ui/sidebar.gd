extends Control

@onready var avatar_label: Label = $Panel/AvatarSection/IconLabel
@onready var name_label: Label = $Panel/AvatarSection/NameLabel
@onready var time_label: Label = $Panel/TimeSection/TimeLabel
@onready var news_container: VBoxContainer = $Panel/NewsSection/ScrollContainer/NewsContainer
@onready var scroll: ScrollContainer = $Panel/NewsSection/ScrollContainer


func _ready():
	EventBus.card_stacked.connect(_on_card_stacked)
	EventBus.card_combined.connect(_on_card_combined)
	EventBus.dialogue_requested.connect(_on_dialogue)
	EventBus.corruption_triggered.connect(_on_corruption)

func add_news(text: String) -> void:
	var ts = Time.get_time_string_from_system()
	var lbl = Label.new()
	lbl.text = "[%s] %s" % [ts, text]
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.modulate = Color(0.7, 0.8, 0.9)
	news_container.add_child(lbl)
	await get_tree().process_frame
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func _on_card_stacked(bottom, top):
	add_news("%s[#%d] 堆叠到 %s[#%d] 上" % [top.card_data.card_name, top.instance_id, bottom.card_data.card_name, bottom.instance_id])

func _on_card_combined(bottom, top, result):
	add_news("合成完成: %s[#%d]" % [result.card_data.card_name, result.instance_id])

func _on_dialogue(_config, character_name, _topic_card_id, _root_card, _topic_card):
	add_news("开始与 %s 对话" % character_name)

func _on_corruption(_card_id):
	add_news("检测到腐化能量波动")
