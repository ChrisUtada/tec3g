extends Node

var _exploration_panel = null
var _dialogue_panel = null
var _current_panel: String = ""


func _ready():
	EventBus.exploration_requested.connect(_on_exploration_requested)
	EventBus.dialogue_requested.connect(_on_dialogue_requested)
	EventBus.exploration_closed.connect(_on_panel_closed)
	EventBus.dialogue_closed.connect(_on_panel_closed)


func register_exploration_panel(panel) -> void:
	_exploration_panel = panel

func register_dialogue_panel(panel) -> void:
	_dialogue_panel = panel

func _on_panel_closed() -> void:
	_current_panel = ""

func _on_exploration_requested(config) -> void:
	if _current_panel == "dialogue" and _dialogue_panel:
		await _dialogue_panel.close()
	elif _current_panel == "exploration" and _exploration_panel:
		await _exploration_panel.close()
	_current_panel = "exploration"
	if _exploration_panel:
		_exploration_panel.open(config)

func _on_dialogue_requested(config, character_name) -> void:
	if _current_panel == "exploration" and _exploration_panel:
		await _exploration_panel.close()
	elif _current_panel == "dialogue" and _dialogue_panel:
		await _dialogue_panel.close()
	_current_panel = "dialogue"
	if _dialogue_panel:
		_dialogue_panel.open(config, character_name)
