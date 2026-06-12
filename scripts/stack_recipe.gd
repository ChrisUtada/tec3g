class_name StackRecipe extends Resource

@export var target_cards: Array[CardData] = []
@export var result_card: CardData = null
@export_range(1, 100) var min_count: int = 1
@export_range(1, 100) var max_count: int = 1
@export_range(0.0, 10.0, 0.1) var weight: float = 1.0
@export_range(0, 100) var max_drops: int = 0
@export var label: String = ""
