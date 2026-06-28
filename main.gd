extends Node2D

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
	var dir = DirAccess.open("res://resources/cards/")
	if dir == null:
		push_warning("main: cannot open res://resources/cards/")
		return
	dir.list_dir_begin()
	var file = dir.get_next()
	while file != "":
		if not dir.current_is_dir() and file.ends_with(".tres"):
			var data = load("res://resources/cards/" + file) as CardData
			if data and data.initial_zone != CardData.InitialZone.NONE:
				match data.initial_zone:
					CardData.InitialZone.BOARD:
						var pos = data.initial_position if data.initial_position != Vector2.ZERO else Vector2(400, 200)
						CardManager.spawn_card(data, pos)
					CardData.InitialZone.STAGING:
						CardManager.spawn_card(data, Vector2(300, CardManager.STAGING_Y + 20))
		file = dir.get_next()
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
