extends Node

var _exploration_panel = null


func _ready():
	EventBus.exploration_requested.connect(_on_exploration_requested)


func register_exploration_panel(panel) -> void:
	_exploration_panel = panel

func _on_exploration_requested(config) -> void:
	if _exploration_panel:
		_exploration_panel.open(config)
