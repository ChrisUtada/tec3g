extends Node2D

func _ready():
	EventBus.set_card_container($GameBoard/CardContainer)

	var sdt = preload("res://resources/cards/ITEM_sdt.tres")
	var observe = preload("res://resources/cards/LOGIC_observe.tres")
	var coin = preload("res://resources/cards/ITEM_coin.tres")
	var peek = preload("res://resources/cards/ITEM_peek_truth.tres")
	var plant_hunter = preload("res://resources/cards/SCENE_plant_hunter.tres")
	var note = preload("res://resources/cards/ITEM_handwritten_note.tres")
	var tec = preload("res://resources/cards/CHAR_tec.tres")
	var junior = preload("res://resources/cards/CHAR_junior_investigator.tres")
	var zhusui = preload("res://resources/cards/CHAR_zhu_sui.tres")

	CardManager.spawn_card(sdt, Vector2(100, 80))
	CardManager.spawn_card(observe, Vector2(330, 80))
	CardManager.spawn_card(plant_hunter, Vector2(560, 80))
	CardManager.spawn_card(tec, Vector2(790, 80))
	CardManager.spawn_card(junior, Vector2(1020, 80))
	CardManager.spawn_card(coin, Vector2(100, 350))
	CardManager.spawn_card(peek, Vector2(330, 350))
	CardManager.spawn_card(note, Vector2(560, 350))
	CardManager.spawn_card(note, Vector2(790, 350))
	CardManager.spawn_card(zhusui, Vector2(1020, 350))

	EventBus.card_stacked.connect(_on_card_stacked)
	EventBus.card_broken.connect(_on_card_broken)
	EventBus.card_combined.connect(_on_card_combined)

func _on_card_stacked(bottom, top):
	$GameBoard/UI/LogLabel.text = "%s 堆叠到 %s 上" % [top.card_data.card_name, bottom.card_data.card_name]

func _on_card_broken(card):
	$GameBoard/UI/LogLabel.text = "%s 断链" % card.card_data.card_name

func _on_card_combined(bottom, top, result):
	$GameBoard/UI/LogLabel.text = "%s + %s → %s 合成成功！" % [bottom.card_data.card_name, top.card_data.card_name, result.card_data.card_name]
