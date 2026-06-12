extends Control

var card_data: CardData : set = set_card_data

var drag_offset := Vector2.ZERO
var is_dragging := false
var _container: Control
var _drag_start_pos := Vector2.ZERO
var _has_moved := false
var _prev_z_index := 0
var _pressed_self := false

const STACK_OFFSET := Vector2(0, 30)
const MIN_DRAG_DISTANCE := 10.0

@onready var background: ColorRect = $Background
@onready var border: ColorRect = $Border
@onready var title_label: Label = $Title
@onready var desc_label: Label = $Description
@onready var type_label: Label = $TypeLabel
@onready var art_rect: TextureRect = $Art

var _hover_tween: Tween
var _press_tween: Tween
var _is_hovered := false
var _orig_border_color: Color
var _corruption_bar: Control


const _bar_scene = preload("res://scenes/progress_bar_2d.tscn")
const _fatigue_card = preload("res://resources/cards/ITEM_fatigue.tres")

func _ready():
	_container = EventBus.get_card_container()
	add_to_group("cards")
	EventBus.register_card(self)
	_refresh_visual()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	if card_data and card_data.corruption_time > 0:
		start_corruption()

func _enter_tree():
	if card_data == null or _container == null:
		return
	EventBus.register_card(self)
	_refresh_visual()

func _exit_tree():
	EventBus.unregister_card(self)

func _on_mouse_entered():
	_is_hovered = true
	if is_dragging:
		return
	_kill_tween(_hover_tween)
	_hover_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.12)
	_hover_tween.parallel().tween_property(border, "color", border.color.lightened(0.4), 0.12)

func _on_mouse_exited():
	_is_hovered = false
	_kill_tween(_hover_tween)
	if is_dragging:
		return
	_hover_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(self, "scale", Vector2.ONE, 0.1)
	_hover_tween.parallel().tween_property(border, "color", _orig_border_color, 0.1)

func _press_effect():
	_kill_tween(_press_tween)
	_press_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_press_tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.06)

func _release_effect():
	_kill_tween(_press_tween)
	_press_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_press_tween.tween_property(self, "scale", Vector2.ONE, 0.08)

static func _kill_tween(t: Tween):
	if t and t.is_valid():
		t.kill()

func setup(data: CardData) -> void:
	card_data = data

func set_card_data(data: CardData) -> void:
	card_data = data
	if is_node_ready():
		_refresh_visual()

func _refresh_visual() -> void:
	if card_data == null:
		return
	background.color = card_data.bg_color
	border.color = card_data.border_color
	_orig_border_color = card_data.border_color
	title_label.text = card_data.card_name
	title_label.modulate = card_data.text_color
	desc_label.text = card_data.description
	type_label.text = _type_text(card_data.card_type, card_data.icon)
	type_label.modulate = card_data.border_color
	if card_data.art:
		art_rect.texture = card_data.art
		art_rect.show()
	else:
		art_rect.texture = null
		art_rect.hide()

static func _type_text(t: CardData.CardType, icon: String) -> String:
	var tag := ""
	match t:
		CardData.CardType.ITEM:  tag = "物品"
		CardData.CardType.CHAR:  tag = "人物"
		CardData.CardType.CLUE:  tag = "线索"
		CardData.CardType.LOGIC: tag = "指令"
		CardData.CardType.SCENE: tag = "场景"
		CardData.CardType.DEBUFF:tag = "状态"
	if icon.is_empty():
		return tag
	return "%s %s" % [icon, tag]


# ── Slot API (for CardSlot) ──
func enter_slot() -> void:
	scale = Vector2(0.6, 0.6)
	z_index = 0
	is_dragging = false
	mouse_filter = MOUSE_FILTER_IGNORE

func exit_slot() -> void:
	scale = Vector2.ONE
	mouse_filter = MOUSE_FILTER_STOP


# ── Drag & Stack ──

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		if card_data and SceneConfigRegistry.get_config(card_data.card_id):
			EventBus.exploration_requested.emit(SceneConfigRegistry.get_config(card_data.card_id))
			return
		if card_data and card_data.dialogue_config:
			EventBus.dialogue_requested.emit(card_data.dialogue_config, card_data.card_name)
			return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_pressed_self = true
		_drag_start_pos = get_global_mouse_position()
		_press_effect()

func _input(event):
	if get_parent() != _container:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_pressed_self = false
		if is_dragging:
			_end_drag()
		else:
			_release_effect()

func _process(delta):
	if _pressed_self and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not is_dragging:
		var dist = get_global_mouse_position().distance_to(_drag_start_pos)
		if dist > MIN_DRAG_DISTANCE:
			_start_drag()
	if is_dragging:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_end_drag()
			return
		var new_pos = get_global_mouse_position() - drag_offset
		if new_pos.distance_to(_drag_start_pos) > MIN_DRAG_DISTANCE:
			_has_moved = true
		global_position = new_pos

func start_drag() -> void:
	if get_parent() != _container:
		reparent(_container)
		EventBus.card_broken.emit(self)
	drag_offset = get_global_mouse_position() - global_position
	is_dragging = true
	_has_moved = false
	_drag_start_pos = global_position
	_prev_z_index = z_index
	z_index = 100
	scale = Vector2.ONE
	border.color = _orig_border_color
	if _corruption_bar:
		_corruption_bar.pause()
	EventBus.card_drag_started.emit(self)

func _start_drag():
	start_drag()

func _end_drag():
	if not is_dragging:
		return
	is_dragging = false
	z_index = _prev_z_index
	scale = Vector2.ONE
	border.color = _orig_border_color
	if _corruption_bar:
		_corruption_bar.resume()
	EventBus.card_drag_ended.emit(self)
	if _has_moved:
		if not _try_slot():
			if not _try_eject():
				_try_stack()
	else:
		_release_effect()

func _try_slot() -> bool:
	var handler = EventBus.get_drop_handler()
	if handler == null:
		return false
	if get_parent() != _container and get_parent() is Control and get_parent().is_in_group("cards"):
		return false
	return handler.on_card_dropped(self)

func _try_eject() -> bool:
	var handler = EventBus.get_drop_handler()
	if handler == null:
		return false
	if handler.has_method("get_panel_left"):
		var panel_left = handler.get_panel_left()
		if global_position.x > panel_left:
			global_position = Vector2(max(panel_left - size.x - 20, 0), global_position.y)
			_release_effect()
			return true
	return false

func start_corruption() -> void:
	await get_tree().process_frame
	var bar = _bar_scene.instantiate()
	bar.set_fill_color(Color(0.8, 0.15, 0.15))
	_corruption_bar = bar
	bar.attach_to(self, card_data.corruption_time, func():
		_corruption_bar = null
		EventBus.spawn_card_requested.emit(
			_fatigue_card,
			global_position
		)
		var container = EventBus.get_card_container()
		for child in get_children():
			if child is Control and child.is_in_group("cards"):
				child.reparent(container)
				child.global_position = global_position + Vector2(0, 80)
		queue_free()
	)

func _try_stack():
	var my_rect = Rect2(global_position, size)
	for card in _container.get_children():
		if card == self or not card.visible:
			continue
		var card_rect = Rect2(card.global_position, card.size)
		if my_rect.intersects(card_rect):
			var target = _top_of_stack(card)
			reparent(target)
			position = STACK_OFFSET
			EventBus.card_stacked.emit(target, self)
			return

static func _top_of_stack(card: Control) -> Control:
	for child in card.get_children():
		if child is Control and child.is_in_group("cards"):
			return _top_of_stack(child)
	return card
