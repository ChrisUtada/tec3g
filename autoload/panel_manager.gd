extends Node

const _exploration_scene = preload("res://scenes/exploration/exploration_panel.tscn")
const _dialogue_scene = preload("res://scenes/dialogue/dialogue_panel.tscn")


func _ready():
	EventBus.exploration_requested.connect(_on_exploration_requested)
	EventBus.dialogue_requested.connect(_on_dialogue_requested)

func _on_exploration_requested(config, result) -> void:
	var panel = _exploration_scene.instantiate()
	get_tree().current_scene.add_child(panel)
	panel.open(config, result)

func _on_dialogue_requested(config, character_name, topic_card_id) -> void:
	var panel = _dialogue_scene.instantiate()
	get_tree().current_scene.add_child(panel)
	panel.open(config, character_name, topic_card_id)
