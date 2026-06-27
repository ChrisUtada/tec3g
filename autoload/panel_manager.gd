extends Node

const _exploration_scene = preload("res://scenes/exploration/exploration_panel.tscn")
const _dialogue_scene = preload("res://scenes/dialogue/dialogue_panel.tscn")
var _dialogue_root_card = null
var _dialogue_topic_card = null


func _ready():
	EventBus.exploration_requested.connect(_on_exploration_requested)
	EventBus.dialogue_requested.connect(_on_dialogue_requested)
	EventBus.card_broken.connect(_on_card_broken)

func _on_exploration_requested(config, result) -> void:
	_close_group("exploration_panel")
	var panel = _exploration_scene.instantiate()
	panel.add_to_group("exploration_panel")
	var scene = get_tree().current_scene
	if scene:
		scene.add_child(panel)
		panel.open(config, result)

func _on_dialogue_requested(config, character_name, topic_card_id, root_card, topic_card) -> void:
	_close_group("dialogue_panel")
	_dialogue_root_card = root_card
	_dialogue_topic_card = topic_card
	var panel = _dialogue_scene.instantiate()
	panel.add_to_group("dialogue_panel")
	var scene = get_tree().current_scene
	if scene:
		scene.add_child(panel)
		panel.open(config, character_name, topic_card_id)

func _on_card_broken(card) -> void:
	if _dialogue_topic_card and card == _dialogue_topic_card:
		_close_dialogue()

func _close_dialogue() -> void:
	_close_group("dialogue_panel")
	_dialogue_root_card = null
	_dialogue_topic_card = null
	EventBus.dialogue_closed.emit()

func _close_group(group: String) -> void:
	if not get_tree():
		return
	for node in get_tree().get_nodes_in_group(group):
		if is_instance_valid(node):
			node.queue_free()
