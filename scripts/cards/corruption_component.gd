extends Node

var _corruption_bar: Control
var _starting := false

const _bar_scene = preload("res://scenes/progress_bar_2d.tscn")
const _fatigue_card = preload("res://resources/cards/ITEM_fatigue.tres")


func start(data: CardData) -> void:
	if _corruption_bar != null or _starting:
		return
	_starting = true
	await get_tree().process_frame
	if not is_inside_tree():
		_starting = false
		return
	var bar = _bar_scene.instantiate()
	bar.set_fill_color(Color(0.8, 0.15, 0.15))
	_corruption_bar = bar
	if not data.corruption_bar_label.is_empty():
		bar.set_label(data.corruption_bar_label)
	var card = get_parent()
	bar.attach_to(card, data.corruption_time, func():
		_corruption_bar = null
		EventBus.corruption_triggered.emit(data.card_id)
		if data.corruption_spawn_fatigue:
			EventBus.spawn_card_requested.emit(
				_fatigue_card,
				card.global_position
			)
		var container = EventBus.get_card_container()
		for child in card.get_children():
			if child is Control and child.is_in_group("cards"):
				child.reparent(container)
				child.global_position = card.global_position + Vector2(0, 80)
		card.queue_free()
	)
	_starting = false

func pause() -> void:
	if _corruption_bar:
		_corruption_bar.pause()

func resume() -> void:
	if _corruption_bar:
		_corruption_bar.resume()
