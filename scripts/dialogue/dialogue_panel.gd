extends Control

var _config: DialogueConfig
var _dialogue_data: Dictionary = {}
var _current_node_id: String = ""
var _topic_card_id: String = ""
var _dragging := false
var _drag_offset := Vector2.ZERO

@onready var content_panel: Panel = $ContentPanel
@onready var title_label: Label = $ContentPanel/Title
@onready var text_label: Label = $ContentPanel/TextLabel
@onready var branch_container: VBoxContainer = $ContentPanel/BranchContainer
@onready var action_btn: Button = $ContentPanel/ActionBtn
@onready var close_btn: Button = $ContentPanel/CloseBtn


func _ready():
	action_btn.pressed.connect(_on_action)
	close_btn.pressed.connect(_close)

func open(config: DialogueConfig, character_name: String, topic_card_id: String) -> void:
	_config = config
	_topic_card_id = topic_card_id
	_dialogue_data = _load_json("res://resources/dialogues/" + config.dialogue_id + ".json")
	_current_node_id = ""
	title_label.text = character_name
	text_label.text = ""
	_clear_branches()
	action_btn.text = "结束对话"
	action_btn.disabled = true
	_center_and_resize()
	_start_dialogue()

func _center_and_resize() -> void:
	await get_tree().process_frame
	var vp = get_viewport().size
	var panel_w = mini(400, vp.x - 80)
	var panel_h = mini(600, vp.y - 80)
	content_panel.custom_minimum_size = Vector2(panel_w, panel_h)
	content_panel.size = Vector2(panel_w, panel_h)
	content_panel.position = Vector2((vp.x - panel_w) * 0.5, (vp.y - panel_h) * 0.5)

func _close() -> void:
	EventBus.dialogue_closed.emit()
	queue_free()

func _start_dialogue() -> void:
	var start_id = _config.start_node_id
	var topics = _dialogue_data.get("topics", {})
	if topics.has(_topic_card_id):
		start_id = topics[_topic_card_id]
	elif topics.has("_default"):
		start_id = topics["_default"]
	var node = _get_node(start_id)
	if node.is_empty():
		text_label.text = "无话可说"
		action_btn.text = "结束对话"
		action_btn.disabled = false
		return
	_current_node_id = start_id
	_show_node(node)

func _show_node(node: Dictionary) -> void:
	_execute_actions(node.get("actions", []))
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

func _on_action() -> void:
	if action_btn.text == "结束对话":
		_close()
	elif not _current_node_id.is_empty():
		_advance_dialogue()

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

func _execute_actions(actions: Array) -> void:
	for action in actions:
		var type = action.get("type", "")
		match type:
			"favorability":
				var target_id = action.get("target_id", "")
				var amount = action.get("amount", 0)
				var card = EventBus.get_card_by_id(target_id)
				if card and card.card_data:
					var old = card.card_data.favorability
					var new_val = mini(old + amount, card.card_data.max_favorability)
					card.card_data.favorability = new_val
					EventBus.favorability_changed.emit(target_id, old, new_val, amount)
			"spawn_card":
				var card_id = action.get("card_id", "")
				if not card_id.is_empty():
					var data = load("res://resources/cards/" + card_id + ".tres")
					if data:
						CardManager.spawn_card(data, _random_spawn_pos())

func _random_spawn_pos() -> Vector2:
	return Vector2(
		randi_range(200, 600),
		randi_range(300, 600)
	)

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

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not _dragging:
			var local = content_panel.get_local_mouse_position()
			if Rect2(Vector2.ZERO, content_panel.size).has_point(local):
				_dragging = true
				_drag_offset = get_global_mouse_position() - content_panel.global_position
		elif not event.pressed:
			_dragging = false

	if event is InputEventMouseMotion and _dragging:
		content_panel.global_position = get_global_mouse_position() - _drag_offset

	if event.is_action_pressed("ui_cancel") and visible:
		_close()
