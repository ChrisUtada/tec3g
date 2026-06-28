extends Node2D

const DesktopLayoutScene = preload("res://scenes/scene_layouts/layout_desktop.tscn")


func _ready():
	EventBus.set_card_container($GameBoard/CardContainer)
	EventBus.set_staging_bar($GameBoard/BottomBar)

	_spawn_initial_cards()

	EventBus.card_stacked.connect(_on_card_stacked)
	EventBus.card_broken.connect(_on_card_broken)
	EventBus.card_combined.connect(_on_card_combined)
	$GameBoard/ButtonBar/OrganizeBtn.pressed.connect(_on_organize_pressed)
	$GameBoard/ButtonBar/StackToggleBtn.pressed.connect(_on_stack_toggle_pressed)


func _spawn_initial_cards() -> void:
	var container = EventBus.get_card_container()
	if not container:
		push_warning("main: no card container available")
		return
	var layout = DesktopLayoutScene.instantiate()
	container.add_child(layout)

	var board_spawns: Array[Dictionary] = []
	var staging_cards: Array[CardData] = []
	for child in layout.get_children():
		var ph := child as CardPlaceholder
		if not ph or not ph.card_data:
			continue
		if ph.zone == CardPlaceholder.PlaceholderZone.BOARD:
			board_spawns.append({"data": ph.card_data, "pos": ph.global_position})
		else:
			staging_cards.append(ph.card_data)
	layout.queue_free()

	for entry in board_spawns:
		CardManager.spawn_card(entry.data, entry.pos)
	for data in staging_cards:
		CardManager.spawn_card(data, Vector2(300, CardManager.STAGING_Y + 20))
	CardManager.arrange_all_staging()

func _on_card_stacked(bottom, top):
	$GameBoard/UI/LogLabel.text = "%s[#%d] 堆叠到 %s[#%d] 上" % [top.card_data.card_name, top.instance_id, bottom.card_data.card_name, bottom.instance_id]

func _on_card_broken(card):
	$GameBoard/UI/LogLabel.text = "%s[#%d] 断链" % [card.card_data.card_name, card.instance_id]

func _on_card_combined(bottom, top, result):
	$GameBoard/UI/LogLabel.text = "%s[#%d] + %s[#%d] → %s[#%d] 合成成功！" % [bottom.card_data.card_name, bottom.instance_id, top.card_data.card_name, top.instance_id, result.card_data.card_name, result.instance_id]

func _on_organize_pressed():
	CardManager.organize_board()

func _on_stack_toggle_pressed():
	CardManager.toggle_staging_layout()
	$GameBoard/ButtonBar/StackToggleBtn.text = "堆叠模式" if CardManager.staging_tiled else "平铺模式"
