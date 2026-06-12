extends Control

var _config: DialogueConfig
var _dialogue_data: Dictionary = {}
var _slot = null
var _current_node_id: String = ""
var _started := false

@onready var panel: Control = $Panel
@onready var title_label: Label = $Panel/Title
@onready var text_label: Label = $Panel/TextLabel
@onready var branch_container: HBoxContainer = $Panel/BranchContainer
@onready var slot_container: Control = $Panel/SlotContainer
@onready var action_btn: Button = $Panel/ActionBtn
@onready var close_btn: Button = $Panel/CloseBtn

const slot_scene = preload("res://scenes/exploration/card_slot.tscn")


func _ready():
	visible = false
	action_btn.pressed.connect(_on_action)
	close_btn.pressed.connect(close)
	panel.position = Vector2(1920, 0)
	EventBus.card_removed_from_slot.connect(_on_card_removed)
	PanelManager.register_dialogue_panel(self)

func _input(event):
	if event.is_action_pressed("ui_cancel") and visible:
		close()

func get_panel_left() -> float:
	return panel.global_position.x

func open(config: DialogueConfig, character_name: String) -> void:
	_config = config
	_dialogue_data = _load_json("res://resources/dialogues/" + config.dialogue_id + ".json")
	_current_node_id = ""
	_started = false
	title_label.text = character_name
	_clear_slot()
	_build_slot()
	visible = true
	text_label.text = ""
	_clear_branches()
	action_btn.text = "开始对话"
	action_btn.disabled = true
	EventBus.register_drop_handler(self)
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "position:x", 1920 - panel.size.x, 0.3)

func close() -> void:
	EventBus.unregister_drop_handler()
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(panel, "position:x", 1920, 0.25)
	await tween.finished
	_clear_slot()
	visible = false
	EventBus.dialogue_closed.emit()

func _build_slot() -> void:
	_slot = slot_scene.instantiate()
	_slot.set_config(null)
	slot_container.add_child(_slot)

func _clear_slot() -> void:
	if _slot and _slot.get_parent():
		var card = _slot.remove_card()
		if card:
			var container = EventBus.get_card_container()
			card.reparent(container, false)
			card.global_position = Vector2(max(get_panel_left() - 180 + randi_range(-40, 40), 0), 400 + randi_range(-80, 80))
		_slot.queue_free()
	_slot = null

func on_card_dropped(card) -> bool:
	if _started:
		return false
	var mouse_pos = get_viewport().get_mouse_position()
	var slot_rect = Rect2(_slot.global_position, _slot.size)
	if slot_rect.has_point(mouse_pos) and _slot.is_empty():
		_slot.place_card(card)
		EventBus.card_placed_in_slot.emit(_slot, card)
		action_btn.disabled = false
		return true
	return false

func _on_card_removed(slot, card) -> void:
	if slot != _slot:
		return
	if not _started:
		action_btn.disabled = true

func _on_action() -> void:
	if not _started:
		_start_dialogue()
	elif action_btn.text == "结束对话":
		_reset_after_dialogue()
	elif not _current_node_id.is_empty():
		_advance_dialogue()

func _reset_after_dialogue() -> void:
	_eject_slot_card()
	_started = false
	_current_node_id = ""
	text_label.text = ""
	_clear_branches()
	action_btn.text = "开始对话"
	action_btn.disabled = true

func _eject_slot_card() -> void:
	if _slot and _slot.get_parent():
		_slot.unlock()
		var card = _slot.remove_card()
		if card:
			var container = EventBus.get_card_container()
			card.reparent(container, false)
			card.global_position = Vector2(max(get_panel_left() - 180 + randi_range(-40, 40), 0), 400 + randi_range(-80, 80))

func _start_dialogue() -> void:
	if _slot.is_empty():
		return
	_started = true
	_slot.lock()
	await get_tree().process_frame
	if _slot.placed_card and _slot.placed_card.get_parent() == _slot:
		_slot.placed_card.enter_slot()
	var node = _get_node(_config.start_node_id)
	if node.is_empty():
		text_label.text = "无话可说"
		action_btn.text = "结束对话"
		action_btn.disabled = false
		return
	_current_node_id = _config.start_node_id
	_show_node(node)

func _show_node(node: Dictionary) -> void:
	text_label.text = node.get("text", "")
	var options = node.get("options", [])
	if options.size() > 0:
		_show_branches(options)
	else:
		_clear_branches()
		var next_id = node.get("next_node_id", "")
		if not next_id.is_empty():
			action_btn.text = "继续"
			action_btn.disabled = false
		else:
			action_btn.text = "结束对话"
			action_btn.disabled = false

func _advance_dialogue() -> void:
	var node = _get_node(_current_node_id)
	if node.is_empty():
		return
	var next_id = node.get("next_node_id", "")
	if next_id.is_empty():
		action_btn.text = "结束对话"
		action_btn.disabled = false
		return
	var next_node = _get_node(next_id)
	if next_node.is_empty():
		text_label.text = "无话可说"
		action_btn.text = "结束对话"
		action_btn.disabled = false
		return
	_current_node_id = next_id
	_show_node(next_node)

func _on_branch_selected(option_data: Dictionary) -> void:
	var next_id = option_data.get("next_node_id", "")
	if next_id.is_empty():
		_clear_branches()
		action_btn.text = "结束对话"
		action_btn.disabled = false
		return
	var next_node = _get_node(next_id)
	if next_node.is_empty():
		_clear_branches()
		text_label.text = "无话可说"
		action_btn.text = "结束对话"
		action_btn.disabled = false
		return
	_current_node_id = next_id
	_show_node(next_node)

func _show_branches(options: Array) -> void:
	_clear_branches()
	action_btn.hide()
	for opt in options:
		var btn = Button.new()
		btn.text = opt.get("text", "")
		btn.pressed.connect(_on_branch_selected.bind(opt))
		branch_container.add_child(btn)
	branch_container.show()

func _clear_branches() -> void:
	for child in branch_container.get_children():
		child.queue_free()
	branch_container.hide()
	action_btn.show()

func _get_node(node_id: String) -> Dictionary:
	return _dialogue_data.get(node_id, {})

func _load_json(path: String) -> Dictionary:
	if path.is_empty():
		return {}
	var text = FileAccess.get_file_as_string(path)
	if text.is_empty():
		return {}
	var json = JSON.parse_string(text)
	return json if json is Dictionary else {}
