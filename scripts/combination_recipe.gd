class_name CombinationRecipe extends Resource

@export var target_id: String = ""      # 目标卡牌ID（堆叠目标）
@export var result_id: String = ""      # 结果卡牌ID（掉落的牌）
@export_range(1, 100) var min_count: int = 1     # 最少掉落数量
@export_range(1, 100) var max_count: int = 1     # 最多掉落数量
@export_range(0.0, 10.0, 0.1) var weight: float = 1.0  # 概率权重
@export_range(0, 100) var max_drops: int = 0           # 最多掉落次数（0=不限）
