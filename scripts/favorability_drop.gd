class_name FavorabilityDrop extends Resource

@export var threshold: String = "low"             # 好感度档位：low / medium / high
@export var result_id: String = ""                # 掉落卡牌ID
@export_range(1, 100) var min_count: int = 1
@export_range(1, 100) var max_count: int = 1
@export_range(0.0, 10.0, 0.1) var weight: float = 1.0
