class_name StackRecipe extends Resource

@export var group_key: String = ""
@export var target_cards: Array[CardData] = []
@export var result_card: CardData = null
@export_range(1, 100) var min_count: int = 1
@export_range(1, 100) var max_count: int = 1
@export_range(0.0, 10.0, 0.1) var weight: float = 1.0
@export_range(0, 100) var max_drops: int = 0

## 销毁 root 及其子卡牌散落到容器
@export var destroys_target: bool = false
## 仅销毁 top 卡牌（及其堆叠子卡），保留 root
@export var consumes_top: bool = false

## 合成后修改堆叠链中 CHAR 卡牌的好感度（正=增加，负=减少）
@export var add_favorability: int = 0

## 条件：堆叠链中必须存在带有指定 tag 的卡牌
@export var require_tags: Array[String] = []
## 条件：堆叠链中 CHAR 卡牌的好感度须 ≥ 此值
@export var require_favorability_min: int = 0

## 连锁标识：同一 chain_id 的配方属于同一条进化/阶段链（元数据，用于总览分组）
@export var chain_id: String = ""

@export var label: String = ""
