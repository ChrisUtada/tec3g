extends Node

var _configs: Dictionary = {}

func _ready():
	_configs["SCENE_plant_hunter"] = _plant_hunter()
	_configs["LOGIC_rest"] = _rest()

func get_config(card_id: String) -> ExplorationConfig:
	return _configs.get(card_id)

func _plant_hunter() -> ExplorationConfig:
	var c = ExplorationConfig.new()
	c.scene_card_id = "SCENE_plant_hunter"
	c.scene_name = "植物学家的花园"
	c.scene_description = "由 TEC 引导进入的异界花园。植物学家在此失踪。\n放入合适的卡牌探索隐藏的秘密。"
	c.slot_count = 3
	c.explore_duration = 3.0

	var branch1 = SlotBranchRecipe.new()
	branch1.branch_name = "采集"
	branch1.required_cards = [
		_slot(["ITEM_sdt"], "需要手电筒"),
		_slot(["ITEM_coin"], "需要因果律"),
	] as Array[PanelSlotConfig]
	branch1.result_recipes = [_drop(preload("res://resources/cards/ITEM_plant.tres"), 1, 1, 1.0, 1, false, "采集植物")] as Array[DropRecipe]
	c.branch_recipes.append(branch1)

	var branch2 = SlotBranchRecipe.new()
	branch2.branch_name = "调查"
	branch2.required_cards = [
		_slot(["CHAR_junior_investigator"], "需要初级调查员"),
	] as Array[PanelSlotConfig]
	branch2.result_recipes = [_drop(preload("res://resources/cards/ITEM_shadow.tres"), 1, 1, 1.0, 0, false, "黑影")] as Array[DropRecipe]
	c.branch_recipes.append(branch2)

	return c

static func _slot(ids: Array[String], hint: String) -> PanelSlotConfig:
	var s = PanelSlotConfig.new()
	s.accept_card_ids = ids
	s.hint = hint
	return s

static func _drop(card: CardData, min_c: int, max_c: int, w: float, drops: int, stackable: bool, label: String) -> DropRecipe:
	var r = DropRecipe.new()
	r.result_card = card
	r.min_count = min_c
	r.max_count = max_c
	r.weight = w
	r.max_drops = drops
	r.stackable = stackable
	r.label = label
	return r

func _rest() -> ExplorationConfig:
	var c = ExplorationConfig.new()
	c.scene_card_id = "LOGIC_rest"
	c.scene_name = "休息处"
	c.scene_description = "让调查员休息，消除疲劳。"
	c.slot_count = 2
	c.explore_duration = 5.0
	c.rest_mode = true
	c.required_cards = [
		_slot(["CHAR_junior_investigator"], "需要初级调查员"),
		_slot(["ITEM_fatigue"], "需要疲劳卡"),
	] as Array[PanelSlotConfig]
	return c
