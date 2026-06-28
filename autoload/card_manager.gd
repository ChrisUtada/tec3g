extends Node

var combo_bar = null
var combo_bottom = null
var combo_top = null
var exploring := false
var dialogue_topic_card = null
var dialogue_root_card = null
var staging_tiled := false
var obs_bar = null
var obs_target = null
var obs_card = null
var open_panels: Dictionary = {}
var _per_game_spawned: Dictionary = {}  # card_id -> true, tracks UNIQUE_PER_GAME spawns

const STAGING_Y := 820
const STAGING_X_GAP := 40
const TILE_X_GAP := 180
const STAGING_VISIBLE := 1418
const STAGING_BAR_LEFT := 280
const STAGING_FIRST_X := 300
const BarScene = preload("res://scenes/progress_bar_2d.tscn")
const CardSceneScene = preload("res://scenes/cards/card_scene.tscn")
const CardBaseScene = preload("res://scenes/cards/card_base.tscn")

var _staging_bar: ColorRect
var _staging_scrollbar: HScrollBar
var _staging_scroll_offset := 0.0


# ── Pending Operation Lifecycle ──

func cancel_combination() -> void:
	if combo_bar:
		combo_bar.cancel()
	combo_bar = null
	combo_bottom = null
	combo_top = null
	exploring = false


func cancel_observation() -> void:
	if obs_bar:
		obs_bar.cancel()
	obs_bar = null
	obs_target = null
	obs_card = null


func cancel_dialogue() -> void:
	if is_instance_valid(dialogue_root_card):
		dialogue_root_card.state = CardBase.CardState.IDLE
	if is_instance_valid(dialogue_topic_card):
		dialogue_topic_card.state = CardBase.CardState.IDLE
	dialogue_topic_card = null
	dialogue_root_card = null


func cancel_all_pending() -> void:
	cancel_combination()
	cancel_observation()
	cancel_dialogue()


func is_combo_in_progress() -> bool:
	return combo_bar != null


func is_dialogue_in_progress() -> bool:
	return dialogue_topic_card != null


func is_panel_open(card_id: String) -> bool:
	return open_panels.has(card_id)


func _ready():
	EventBus.card_stacked.connect(_on_card_stacked)
	EventBus.spawn_card_requested.connect(_on_spawn_card_requested)
	EventBus.card_broken.connect(_on_card_broken)
	EventBus.dialogue_closed.connect(_on_dialogue_closed)
	EventBus.staging_arrange_requested.connect(_on_staging_arrange_requested)
	call_deferred("_setup_staging_area")


func _setup_staging_area() -> void:
	var container = EventBus.get_card_container()
	if not container or _staging_bar:
		return
	_staging_bar = EventBus.get_staging_bar()
	if not _staging_bar:
		return

	_staging_scrollbar = HScrollBar.new()
	_staging_scrollbar.name = "StagingScrollbar"
	_staging_scrollbar.value_changed.connect(_on_staging_scrolled)
	_staging_scrollbar.visible = false
	_staging_scrollbar.position = Vector2(0, _staging_bar.size.y - 20)
	_staging_scrollbar.size = Vector2(STAGING_VISIBLE, 20)
	_staging_bar.add_child(_staging_scrollbar)

	_staging_bar.gui_input.connect(_on_staging_bar_gui_input)
	container.resized.connect(_resize_staging_area)
	arrange_all_staging()


func _on_staging_bar_gui_input(event: InputEvent) -> void:
	if not _staging_scrollbar.visible:
		return
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_staging_scrollbar.value = max(0, _staging_scrollbar.value - 100)
			MOUSE_BUTTON_WHEEL_DOWN:
				_staging_scrollbar.value = min(_staging_scrollbar.max_value, _staging_scrollbar.value + 100)


func _resize_staging_area() -> void:
	if _staging_scrollbar and _staging_bar:
		_staging_scrollbar.position.y = _staging_bar.size.y - 20


func _on_staging_scrolled(value: float) -> void:
	_staging_scroll_offset = value
	if not _staging_bar:
		return
	for child in _staging_bar.get_children():
		if child is Control and child.is_in_group("cards"):
			var base_x = child.get_meta("staging_base_x", null)
			if base_x != null:
				child.position.x = base_x - _staging_scroll_offset


func _on_card_broken(card):
	if exploring:
		cancel_combination()
		return
	if combo_bar and card == combo_top:
		cancel_combination()
	if obs_bar and card == obs_card:
		cancel_observation()


func _on_card_stacked(bottom, top):
	if bottom.card_data == null or top.card_data == null:
		return
	# 1. 观察：top 是 LOGIC_observe 且 bottom 有多媒体内容 → 观察系统
	if top.card_data.card_id == "LOGIC_observe" and bottom.card_data.multimedia_content:
		if not is_panel_open(bottom.card_data.card_id):
			ObservationSystem.start(bottom, top)
		return
	var root = _stack_root(bottom)
	if not root.card_data:
		return
	# 2. 场景卡不可堆叠（双击进入，不走堆叠路由）
	if root is CardScene:
		return
	# 3. 探索：root 有注册的探索配置 → 探索系统
	var exp_config = SceneConfigRegistry.get_config(root.card_data.card_id)
	if exp_config:
		ExplorationSystem.start(root, exp_config)
		return
	# 4. 对话：root 有对话配置 → 对话系统
	if root.card_data.dialogue_config:
		DialogueSystem.start(root, top)
		return
	# 5. 兜底：组合系统（配方匹配）
	CombinationSystem.start(root, top)


func _on_spawn_card_requested(data: CardData, global_position: Vector2) -> void:
	spawn_card(data, global_position)


func _on_dialogue_closed() -> void:
	cancel_dialogue()


func _on_staging_arrange_requested(dropped_card, was_in_staging: bool) -> void:
	arrange_staging_area(dropped_card, was_in_staging)


func arrange_staging_area(dropped_card: Control, was_in_staging: bool) -> void:
	var container = EventBus.get_card_container()
	var cards = _collect_staging_cards(container, dropped_card)

	var gap = TILE_X_GAP if staging_tiled else STAGING_X_GAP
	var drop_center = dropped_card.global_position.x + dropped_card.size.x / 2
	var insert_idx = cards.size()
	for i in range(cards.size()):
		var theoretical_center = STAGING_FIRST_X + i * gap - _staging_scroll_offset + dropped_card.size.x / 2
		if drop_center < theoretical_center:
			insert_idx = i
			break
	cards.insert(insert_idx, dropped_card)

	_arrange_staging_cards(cards, TILE_X_GAP if staging_tiled else STAGING_X_GAP)


func _arrange_staging_cards(cards: Array[Control], gap: int) -> void:
	var x = STAGING_FIRST_X
	for i in range(cards.size()):
		var card = cards[i]
		card.set_staging_mode(true)
		card.set_meta("staging_base_x", x - STAGING_BAR_LEFT)
		if _staging_bar:
			if card.get_parent() != _staging_bar:
				card.reparent(_staging_bar)
			card.position = Vector2(x - STAGING_BAR_LEFT, 20)
		else:
			card.global_position = Vector2(x, STAGING_Y + 20)
		x += gap
	# 修正 z-order：reparent 会把卡牌追加到末尾（最顶层），
	# 需要按数组顺序重排子节点，让左侧卡牌在底层、右侧在顶层。
	if _staging_bar:
		for i in range(cards.size()):
			_staging_bar.move_child(cards[i], i)

	var total_width = x - STAGING_FIRST_X
	if _staging_scrollbar:
		if total_width > STAGING_VISIBLE:
			_staging_scrollbar.visible = true
			_staging_scrollbar.max_value = total_width - STAGING_VISIBLE
			_staging_scrollbar.page = 0
			_staging_scrollbar.value = min(_staging_scrollbar.value, _staging_scrollbar.max_value)
		else:
			_staging_scrollbar.visible = false
			_staging_scrollbar.value = 0
			_staging_scrollbar.max_value = 0
			_staging_scroll_offset = 0


func _collect_staging_cards(container: Control, exclude: Control = null) -> Array[Control]:
	var cards: Array[Control] = []
	for child in container.get_children():
		if child is Control and child.is_in_group("cards") and child != exclude:
			if _staging_bar and child.get_parent() == _staging_bar:
				continue
			if child.global_position.y >= STAGING_Y:
				cards.append(child)
	if _staging_bar:
		for child in _staging_bar.get_children():
			if child is Control and child.is_in_group("cards") and child != exclude:
				cards.append(child)
	return cards


func arrange_all_staging() -> void:
	var container = EventBus.get_card_container()
	var cards = _collect_staging_cards(container)
	_arrange_staging_cards(cards, STAGING_X_GAP)


func toggle_staging_layout() -> void:
	staging_tiled = not staging_tiled
	var container = EventBus.get_card_container()
	var cards = _collect_staging_cards(container)
	_arrange_staging_cards(cards, TILE_X_GAP if staging_tiled else STAGING_X_GAP)


func can_spawn(data: CardData) -> bool:
	match data.spawn_policy:
		CardData.SpawnPolicy.UNIQUE_ON_BOARD:
			return not EventBus.has_card_on_board(data.card_id)
		CardData.SpawnPolicy.UNIQUE_PER_GAME:
			return not _per_game_spawned.has(data.card_id)
	return true


func reset_spawn_tracking() -> void:
	_per_game_spawned.clear()


func spawn_card(data: CardData, global_position: Vector2, source: Control = null) -> Control:
	if not can_spawn(data):
		return null
	if data.spawn_policy == CardData.SpawnPolicy.UNIQUE_PER_GAME:
		_per_game_spawned[data.card_id] = true
	var scene: PackedScene = data.get_card_scene()
	if not scene:
		scene = CardSceneScene if data.card_type == CardData.CardType.SCENE else CardBaseScene
	var card = scene.instantiate()
	card.setup(data)
	if source:
		card.spawn_source = source
		if card is CardScene and source is CardScene:
			card.origin_scene = source
	var container = EventBus.get_card_container()
	container.add_child(card)
	card.global_position = global_position
	EventBus.register_card(card)
	EventBus.card_created.emit(card)
	return card


func organize_board() -> void:
	var container = EventBus.get_card_container()
	var scene_cards: Array[Control] = []
	var spawn_map: Dictionary = {}
	for card in container.get_children():
		if card is Control and card.is_in_group("cards") and card.card_data:
			if card.global_position.y >= CardManager.STAGING_Y:
				continue
		if card is CardScene:
			scene_cards.append(card)
		elif card.spawn_source:
				var key = card.spawn_source
				if not spawn_map.has(key):
					spawn_map[key] = []
				spawn_map[key].append(card)
	for scene in scene_cards:
		var spawns = spawn_map.get(scene, [])
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


static func collect_stack_ids(root: Control) -> Array[String]:
	var ids: Array[String] = [root.card_data.card_id]
	var queue: Array = root.get_children()
	while queue.size() > 0:
		var child = queue.pop_front()
		if child is Control and child.is_in_group("cards"):
			ids.append(child.card_data.card_id)
			for gc in child.get_children():
				queue.append(gc)
	return ids
