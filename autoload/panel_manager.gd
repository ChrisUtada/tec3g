extends Node

const _exploration_scene = preload("res://scenes/exploration/exploration_panel.tscn")
const _dialogue_scene = preload("res://scenes/dialogue/dialogue_panel.tscn")


func _ready():
	EventBus.exploration_requested.connect(_on_exploration_requested)
	EventBus.dialogue_requested.connect(_on_dialogue_requested)

func _on_exploration_requested(config, result) -> void:
	_close_group("exploration_panel")
	var panel = _exploration_scene.instantiate()
	panel.add_to_group("exploration_panel")
	get_tree().current_scene.add_child(panel)
	panel.open(config, result)

func _on_dialogue_requested(config, character_name, topic_card_id) -> void:
	_close_group("dialogue_panel")
	var panel = _dialogue_scene.instantiate()
	panel.add_to_group("dialogue_panel")
	get_tree().current_scene.add_child(panel)
	panel.open(config, character_name, topic_card_id)

func _close_group(group: String) -> void:
	for node in get_tree().get_nodes_in_group(group):
		if is_instance_valid(node):
			node.queue_free()
