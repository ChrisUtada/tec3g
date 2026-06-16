class_name ExplorationConfig extends Resource

@export var scene_card_id: String = ""
@export var scene_name: String = ""
@export_multiline var scene_description: String = ""
@export var explore_duration: float = 3.0
@export var result_recipes: Array[DropRecipe] = []
@export var branch_recipes: Array[SlotBranchRecipe] = []
@export var rest_mode: bool = false
