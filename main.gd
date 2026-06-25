extends Node2D

func _ready():
	EventBus.set_card_container($GameBoard/CardContainer)

	var sdt = preload("res://resources/cards/ITEM_sdt.tres")
	var observe = preload("res://resources/cards/LOGIC_observe.tres")
	var capture = preload("res://resources/cards/LOGIC_capture.tres")
	var rest = preload("res://resources/cards/LOGIC_rest.tres")
	var coin = preload("res://resources/cards/ITEM_coin.tres")
	var peek = preload("res://resources/cards/ITEM_peek_truth.tres")
	var plant_hunter = preload("res://resources/cards/SCENE_plant_hunter.tres")
	var tec = preload("res://resources/cards/CHAR_tec.tres")
	var junior = preload("res://resources/cards/CHAR_junior_investigator.tres")
	var zhusui = preload("res://resources/cards/CHAR_zhu_sui.tres")

	CardManager.spawn_card(sdt, Vector2(300, 80))
	CardManager.spawn_card(observe, Vector2(530, 80))
	CardManager.spawn_card(capture, Vector2(760, 80))
	CardManager.spawn_card(rest, Vector2(990, 80))
	CardManager.spawn_card(plant_hunter, Vector2(1220, 80))
	CardManager.spawn_card(tec, Vector2(300, 350))
	CardManager.spawn_card(junior, Vector2(530, 350))
	CardManager.spawn_card(coin, Vector2(760, 350))
	CardManager.spawn_card(peek, Vector2(990, 350))
	CardManager.spawn_card(zhusui, Vector2(1220, 350))

	EventBus.card_stacked.connect(_on_card_stacked)
	EventBus.card_broken.connect(_on_card_broken)
	EventBus.card_combined.connect(_on_card_combined)
	$GameBoard/BottomBar/OrganizeBtn.pressed.connect(_on_organize_pressed)
	$GameBoard/BottomBar/StackToggleBtn.pressed.connect(_on_stack_toggle_pressed)

func _on_card_stacked(bottom, top):
	$GameBoard/UI/LogLabel.text = "%s 堆叠到 %s 上" % [top.card_data.card_name, bottom.card_data.card_name]

func _on_card_broken(card):
	$GameBoard/UI/LogLabel.text = "%s 断链" % card.card_data.card_name

func _on_card_combined(bottom, top, result):
	$GameBoard/UI/LogLabel.text = "%s + %s → %s 合成成功！" % [bottom.card_data.card_name, top.card_data.card_name, result.card_data.card_name]

func _on_organize_pressed():
	CardManager.organize_board()

func _on_stack_toggle_pressed():
	CardManager.toggle_staging_layout()
	$GameBoard/BottomBar/StackToggleBtn.text = "堆叠模式" if CardManager.staging_tiled else "平铺模式"
