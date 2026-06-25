extends Node

var combo_bar = null
var combo_bottom = null
var combo_top = null
var exploring := false
var dialogue_topic_card = null

const BarScene = preload("res://scenes/progress_bar_2d.tscn")


func _ready():
	EventBus.card_stacked.connect(_on_card_stacked)
	EventBus.spawn_card_requested.connect(_on_spawn_card_requested)
	EventBus.card_broken.connect(_on_card_broken)
	EventBus.dialogue_closed.connect(_on_dialogue_closed)


func _on_card_broken(card):
	if exploring:
		if combo_bar:
			combo_bar.cancel()
		combo_bar = null
		combo_bottom = null
		combo_top = null
		exploring = false
		return
	if combo_bar and card == combo_top:
		combo_bar.cancel()
		combo_bar = null
		combo_bottom = null
		combo_top = null


func _on_card_stacked(bottom, top):
	if bottom.card_data == null or top.card_data == null:
		return
	if top.card_data.card_id == "LOGIC_observe" and bottom.card_data.multimedia_content:
		ObservationSystem.start(bottom, top)
		return
	var root = _stack_root(bottom)
	if not root.card_data:
		return
	var exp_config = SceneConfigRegistry.get_config(root.card_data.card_id)
	if exp_config:
		ExplorationSystem.start(root, exp_config)
		return
	if root.card_data.dialogue_config:
		DialogueSystem.start(root, top)
		return
	CombinationSystem.start(root, top)


func _on_spawn_card_requested(data: CardData, global_position: Vector2) -> void:
	spawn_card(data, global_position)


func _on_dialogue_closed() -> void:
	if dialogue_topic_card and is_instance_valid(dialogue_topic_card) and dialogue_topic_card.is_inside_tree():
		var container = EventBus.get_card_container()
		dialogue_topic_card.reparent(container)
		dialogue_topic_card.global_position = Vector2(randi_range(200, 600), randi_range(300, 600))
	dialogue_topic_card = null


func spawn_card(data: CardData, global_position: Vector2, source: Control = null) -> Control:
	var scene = preload("res://scenes/cards/card_base.tscn")
	var card = scene.instantiate()
	card.setup(data)
	if source:
		card.spawn_source = source
	var container = EventBus.get_card_container()
	container.add_child(card)
	card.global_position = global_position
	EventBus.register_card(card)
	EventBus.card_created.emit(card)
	return card


func organize_board() -> void:
	var container = EventBus.get_card_container()
	var scene_cards: Array[Control] = []
	for card in container.get_children():
		if card is Control and card.is_in_group("cards") and card.card_data:
			if card.card_data.card_type == CardData.CardType.SCENE and card.global_position.y < 820:
				scene_cards.append(card)
	for scene in scene_cards:
		var spawns: Array[Control] = []
		for card in container.get_children():
			if card is Control and card.is_in_group("cards") and card.card_data:
				if card.global_position.y >= 820:
					continue
				if card.spawn_source == scene:
					spawns.append(card)
		var target = scene
		for s in spawns:
			s.reparent(target)
			s.position = Vector2(0, 30)
			target = s


static func _stack_root(card: Control) -> Control:
	var parent = card.get_parent()
	if parent is Control and parent.is_in_group("cards"):
		return _stack_root(parent)
	return card
