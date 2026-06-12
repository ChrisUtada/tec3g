extends Control

var _config: ExplorationConfig
var _slots: Array = []
var _exploring := false
var _tween: Tween

@onready var panel: Control = $Panel
@onready var title_label: Label = $Panel/Title
@onready var desc_label: Label = $Panel/Desc
@onready var slot_container: Control = $Panel/SlotContainer
@onready var progress_bar: ColorRect = $Panel/ProgressBar
@onready var progress_fill: ColorRect = $Panel/ProgressBar/Fill
@onready var start_btn: Button = $Panel/StartBtn
@onready var status_label: Label = $Panel/StatusLabel
@onready var close_btn: Button = $Panel/CloseBtn
@onready var slot_scene = preload("res://scenes/exploration/card_slot.tscn")


func _ready():
	visible = false
	start_btn.pressed.connect(_on_start)
	close_btn.pressed.connect(close)
	panel.position = Vector2(1920, 0)
	EventBus.card_removed_from_slot.connect(_on_card_removed)
	PanelManager.register_exploration_panel(self)

func _input(event):
	if event.is_action_pressed("ui_cancel") and visible:
		close()

func get_panel_left() -> float:
	return panel.global_position.x

func open(config: ExplorationConfig) -> void:
	_config = config
	_exploring = false
	progress_fill.size.x = 0
	_kill_tween(_tween)
	title_label.text = config.scene_name
	desc_label.text = config.scene_description
	_build_slots()
	visible = true
	start_btn.disabled = true
	status_label.text = "放入卡牌到槽位中…"
	EventBus.register_drop_handler(self)
	_kill_tween(_tween)
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(panel, "position:x", 1920 - panel.size.x, 0.3)

func close() -> void:
	EventBus.unregister_drop_handler()
	_kill_tween(_tween)
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(panel, "position:x", 1920, 0.25)
	await _tween.finished
	_clear_slots()
	visible = false
	EventBus.exploration_closed.emit()

func _build_slots() -> void:
	_clear_slots()
	var count = _config.slot_count
	var cfgs = _config.slot_configs
	for i in range(count):
		var slot = slot_scene.instantiate()
		slot.set_config(cfgs[i] if i < cfgs.size() else null)
		slot_container.add_child(slot)
		_slots.append(slot)

func _clear_slots() -> void:
	for slot in _slots:
		var card = slot.remove_card()
		if card:
			var container = EventBus.get_card_container()
			card.reparent(container)
			card.global_position = Vector2(randi_range(200, 600), randi_range(300, 600))
		slot.queue_free()
	_slots.clear()

func on_card_dropped(card) -> bool:
	if _exploring:
		return false
	if not _is_card_valid(card):
		return false
	var mouse_pos = get_viewport().get_mouse_position()
	for slot in _slots:
		var slot_rect = Rect2(slot.global_position, slot.size)
		if slot_rect.has_point(mouse_pos) and slot.is_empty():
			slot.place_card(card)
			EventBus.card_placed_in_slot.emit(slot, card)
			_check_ready()
			return true
	return false

func _is_card_valid(card) -> bool:
	if _config.branch_recipes.is_empty():
		for req in _config.required_cards:
			if req.matches(card):
				return true
		return false
	for branch in _config.branch_recipes:
		for req in branch.required_cards:
			if req.matches(card):
				return true
	return false

func _on_card_removed(slot, card) -> void:
	if _config == null:
		return
	_check_ready()

func _check_ready() -> void:
	if not _config.branch_recipes.is_empty():
		for branch in _config.branch_recipes:
			if _match_slots(branch.required_cards):
				start_btn.disabled = false
				status_label.text = "准备就绪，可以开始探索"
				return
		start_btn.disabled = true
		status_label.text = "放入卡牌到槽位中…"
		return
	var reqs = _config.required_cards
	for req in reqs:
		var found := false
		for slot in _slots:
			if not slot.is_empty() and req.matches(slot.placed_card):
				found = true
				break
		if not found:
			start_btn.disabled = true
			status_label.text = "放入卡牌到槽位中…"
			return
	start_btn.disabled = false
	status_label.text = "准备就绪，可以开始探索"

func _on_start() -> void:
	if _exploring:
		return
	_exploring = true
	start_btn.disabled = true
	status_label.text = "探索中…"
	progress_fill.size.x = 0
	for slot in _slots:
		if not slot.is_empty():
			slot.lock()
	_kill_tween(_tween)
	_tween = create_tween()
	_tween.tween_property(progress_fill, "size:x", progress_bar.size.x, _config.explore_duration)
	_tween.tween_callback(_on_explore_end)
	EventBus.exploration_started.emit()

func _on_explore_end() -> void:
	_exploring = false
	_return_cards()
	progress_fill.size.x = 0
	_check_ready()
	var active_recipes = _get_active_recipes()
	var base_pos = Vector2(get_panel_left() - 200, 500)
	var fatigue_count = EventBus.get_cards_by_tag("fatigue").size()
	var drop_multiplier = max(0.0, 1.0 - fatigue_count * 0.2)
	if randf() < 0.25:
		EventBus.spawn_card_requested.emit(
			load("res://resources/cards/ITEM_fatigue.tres"),
			base_pos + Vector2(-60, 0)
		)
		status_label.text = "获得: 疲劳"
		await get_tree().create_timer(0.3).timeout
	for recipe in active_recipes:
		if not EventBus.can_drop(recipe):
			continue
		if fatigue_count > 0 and randf() >= drop_multiplier:
			continue
		EventBus.mark_drop_consumed(recipe)
		var path = "res://resources/cards/" + recipe.result_id + ".tres"
		var data = load(path) as CardData
		if data == null:
			continue
		var count = randi_range(recipe.min_count, recipe.max_count)
		for i in range(count):
			var pos = base_pos + Vector2(i * 30, 0)
			EventBus.spawn_card_requested.emit(data, pos)
			status_label.text = "获得: %s" % data.card_name
			await get_tree().create_timer(0.3).timeout
	status_label.text = "探索完成，可重新放入卡牌"
	EventBus.exploration_completed.emit()

func _get_active_recipes() -> Array:
	if _config.branch_recipes.is_empty():
		return _config.result_recipes
	for branch in _config.branch_recipes:
		if _match_slots(branch.required_cards):
			return branch.result_recipes
	return _config.result_recipes

func _match_slots(reqs: Array) -> bool:
	for req in reqs:
		var found := false
		for slot in _slots:
			if not slot.is_empty() and req.matches(slot.placed_card):
				found = true
				break
		if not found:
			return false
	return true

func _return_cards() -> void:
	var panel_left = get_panel_left()
	for slot in _slots:
		var card = slot.remove_card()
		if card:
			var container = EventBus.get_card_container()
			card.reparent(container, false)
			card.global_position = Vector2(panel_left - 180 + randi_range(-40, 40), 400 + randi_range(-80, 80))
		slot.unlock()

func _kill_tween(t: Tween) -> void:
	if t and t.is_valid():
		t.kill()
