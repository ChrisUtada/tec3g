extends Node


func start(target, observe_card) -> void:
	var bar = CardManager.BarScene.instantiate()
	bar.set_fill_color(Color(0.5, 0.3, 1.0))
	CardManager.combo_bar = bar
	CardManager.combo_bottom = target
	CardManager.combo_top = observe_card
	bar.attach_to(target, 3.0, func():
		bar.queue_free()
		CardManager.combo_bar = null
		CardManager.combo_bottom = null
		CardManager.combo_top = null
		var panel = preload("res://scenes/multimedia_panel.tscn").instantiate()
		var scene = get_tree().current_scene
		if scene:
			scene.add_child(panel)
		panel.open(target.card_data.multimedia_content)
	)
