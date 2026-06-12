extends Node

var _bar_scene = preload("res://scenes/progress_bar_2d.tscn")

func start_progress(pos: Vector2, duration: float, on_complete: Callable) -> void:
	var container = EventBus.get_card_container()
	if container == null:
		on_complete.call()
		return
	var bar = _bar_scene.instantiate()
	container.add_child(bar)
	bar.start(pos, duration, on_complete)
