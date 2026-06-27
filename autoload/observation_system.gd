extends Node


func start(target, observe_card) -> void:
	if CardManager.obs_bar != null:
		return
	var bar = CardManager.BarScene.instantiate()
	bar.set_fill_color(Color(0.5, 0.3, 1.0))
	CardManager.obs_bar = bar
	CardManager.obs_target = target
	CardManager.obs_card = observe_card
	bar.attach_to(target, 3.0, func():
		bar.queue_free()
		CardManager.obs_bar = null
		CardManager.obs_target = null
		CardManager.obs_card = null
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
