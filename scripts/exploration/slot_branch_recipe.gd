class_name SlotBranchRecipe extends Resource

@export var branch_name: String = ""
@export var required_cards: Array[PanelSlotConfig] = []
@export var result_recipes: Array[DropRecipe] = []
@export var add_favorability: int = 0
@export var favorability_target_slot: int = -1
