extends Node

@export var recipes: Array[StackRecipe] = []

var _recipes: Dictionary = {}  # card_id -> Array[StackRecipe]


func _ready():
	_recipes.clear()
	for r in recipes:
		if r == null or r.target_cards.is_empty() or r.target_cards[0] == null:
			push_warning("RecipeRegistry: skipping invalid recipe")
			continue
		var key = r.group_key
		if key.is_empty():
			push_warning("RecipeRegistry: recipe '%s' has empty group_key" % r.label)
			continue
		if not _recipes.has(key):
			_recipes[key] = []
		_recipes[key].append(r)


func get_recipes(card_id: String) -> Array:
	return _recipes.get(card_id, [])
