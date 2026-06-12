extends Node

var _exploration_panel = null
var _dialogue_panel = null


func _ready():
	EventBus.exploration_requested.connect(_on_exploration_requested)
	EventBus.dialogue_requested.connect(_on_dialogue_requested)


func register_exploration_panel(panel) -> void:
	_exploration_panel = panel

func register_dialogue_panel(panel) -> void:
	_dialogue_panel = panel

func _on_exploration_requested(config) -> void:
	if _exploration_panel:
		_exploration_panel.open(config)

func _on_dialogue_requested(config, character_name) -> void:
	if _dialogue_panel:
		_dialogue_panel.open(config, character_name)
