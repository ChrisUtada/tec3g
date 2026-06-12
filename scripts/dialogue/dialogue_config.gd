class_name DialogueConfig extends Resource

@export var dialogue_id: String = ""
@export var title: String = "对话"
@export var start_node_id: String = "start"

# { node_id: { text, next_node_id?, options?: [{text, next_node_id}] } }
@export var dialogue_data: Dictionary = {}
