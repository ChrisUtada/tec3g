extends Node

@export var configs: Array[ExplorationConfig] = []

var _configs: Dictionary = {}


func _ready():
	_configs.clear()
	for c in configs:
		if c == null:
			continue
		if c.scene_card_id.is_empty():
			push_warning("SceneConfigRegistry: config '%s' has empty scene_card_id" % c.resource_path)
			continue
		_configs[c.scene_card_id] = c


func get_config(card_id: String) -> ExplorationConfig:
	return _configs.get(card_id)
