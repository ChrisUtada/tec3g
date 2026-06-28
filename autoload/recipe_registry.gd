extends Node

var _recipes: Dictionary = {}  # group_key -> Array[StackRecipe]


func _ready():
	_scan_recipes()


func _scan_recipes() -> void:
	_recipes.clear()
	var dir = DirAccess.open("res://resources/recipes/")
	if dir == null:
		push_warning("RecipeRegistry: cannot open res://resources/recipes/")
		return
	dir.list_dir_begin()
	var file = dir.get_next()
	while file != "":
		if not dir.current_is_dir() and file.ends_with(".tres"):
			var r = load("res://resources/recipes/" + file) as StackRecipe
			if r:
				var key = r.group_key
				if key.is_empty():
					push_warning("RecipeRegistry: recipe '%s' has empty group_key" % file)
				else:
					if not _recipes.has(key):
						_recipes[key] = []
					_recipes[key].append(r)
		file = dir.get_next()


func get_recipes(card_id: String) -> Array:
	return _recipes.get(card_id, [])


func reload() -> void:
	_scan_recipes()
