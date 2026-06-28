extends Node


func start(target, observe_card) -> void:
	if CardManager.obs_bar != null:
		return
	var bar = CardManager.BarScene.instantiate()
	bar.set_fill_color(Color(0.5, 0.3, 1.0))
	bar.set_label("观察中...")
	CardManager.obs_bar = bar
	CardManager.obs_target = target
	CardManager.obs_card = observe_card
	bar.attach_to(target, 3.0, func():
		bar.queue_free()
		CardManager.obs_bar = null
		CardManager.obs_target = null
		CardManager.obs_card = null
		# 卡牌可能被外部机制销毁 → 跳过观察
		if not is_instance_valid(target) or not is_instance_valid(observe_card):
			return
		var panel = preload("res://scenes/multimedia_panel.tscn").instantiate()
		var scene = get_tree().current_scene
		if scene:
			scene.add_child(panel)
		CardManager.open_panels[target.card_data.card_id] = true
		panel.tree_exited.connect(func():
			CardManager.open_panels.erase(target.card_data.card_id)
		)
		panel.open(target.card_data.multimedia_content)
	)
