class_name DropRecipe extends Resource

@export var result_card: CardData = null
@export_range(1, 100) var min_count: int = 1
@export_range(1, 100) var max_count: int = 1
@export_range(0.0, 10.0, 0.1) var weight: float = 1.0
@export_range(0, 100) var max_drops: int = 0
@export var stackable: bool = false
@export var no_duplicate: bool = false
@export var unique: bool = false
@export var label: String = ""
