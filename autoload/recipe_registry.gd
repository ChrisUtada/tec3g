extends Node

var _recipes: Dictionary = {}  # card_id -> Array[StackRecipe]

func _ready():
	_register("ITEM_sdt", [
		_recipe([preload("res://resources/cards/LOGIC_observe.tres")] as Array[CardData], preload("res://resources/cards/ITEM_peek_truth.tres"), 1, 2, 1.0, 0, "窥视真相"),
		_recipe([preload("res://resources/cards/LOGIC_observe.tres")] as Array[CardData], preload("res://resources/cards/ITEM_coin.tres"), 1, 3, 0.4, 0, "因果律之币"),
		_recipe([preload("res://resources/cards/ITEM_coin.tres")] as Array[CardData], preload("res://resources/cards/ITEM_plant.tres"), 1, 1, 1.0, 1, "种出植物"),
		_recipe([preload("res://resources/cards/ITEM_peek_truth.tres")] as Array[CardData], preload("res://resources/cards/ITEM_corrupted_sample.tres"), 1, 1, 1.0, 1, "腐化"),
	])
	_register("LOGIC_capture", [
		_recipe([preload("res://resources/cards/CHAR_zhu_sui.tres")] as Array[CardData], preload("res://resources/cards/ITEM_handwritten_note.tres"), 1, 1, 1.0, 1, "捕获→手写笔记"),
	])

func get_recipes(card_id: String) -> Array:
	return _recipes.get(card_id, [])

func _register(card_id: String, recipes: Array) -> void:
	_recipes[card_id] = recipes

static func _recipe(targets: Array[CardData], result: CardData, min_c: int, max_c: int, w: float, drops: int, label: String) -> StackRecipe:
	var r = StackRecipe.new()
	r.target_cards = targets
	r.result_card = result
	r.min_count = min_c
	r.max_count = max_c
	r.weight = w
	r.max_drops = drops
	r.label = label
	return r
