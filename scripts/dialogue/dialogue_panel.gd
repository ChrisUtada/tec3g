extends Control

var _config: DialogueConfig
var _dialogue_data: Dictionary = {}
var _current_node_id: String = ""
var _topic_card_id: String = ""
var _current_speaker_name: String = ""
var _type_timer: float = 0.0
var _type_index: int = 0
var _typing := false
var _text_complete := false
var _full_text: String = ""
var _waiting_for_click := false
var _speaker_card: Control = null

const TYPE_SPEED := 0.035
const POPUP_W := 700
const POPUP_H := 300

@onready var bg_panel: Panel = $BgPanel
@onready var portrait_rect: TextureRect = $BgPanel/PortraitMargin/Portrait
@onready var portrait_bg: ColorRect = $BgPanel/PortraitMargin/PortraitBg
@onready var portrait_margin: Control = $BgPanel/PortraitMargin
@onready var speaker_label: Label = $BgPanel/SpeakerName
@onready var text_label: Label = $BgPanel/TextLabel
@onready var branch_container: VBoxContainer = $BgPanel/BranchContainer
@onready var continue_btn: Button = $BgPanel/ContinueBtn
@onready var close_btn: Button = $BgPanel/CloseBtn


func _ready():
	continue_btn.pressed.connect(_on_continue)
	close_btn.pressed.connect(_close)
	continue_btn.hide()


func open(config: DialogueConfig, character_name: String, topic_card_id: String) -> void:
	_config = config
	_topic_card_id = topic_card_id
	_dialogue_data = _load_json("res://resources/dialogues/" + config.dialogue_id + ".json")
	_current_node_id = ""
	_current_speaker_name = character_name
	_set_speaker_by_id("")
	text_label.text = ""
	_clear_branches()
	_position_popup()
	_start_dialogue()


func _position_popup() -> void:
	await get_tree().process_frame
	var vp = get_viewport().size
	bg_panel.custom_minimum_size = Vector2(POPUP_W, POPUP_H)
	bg_panel.size = Vector2(POPUP_W, POPUP_H)
	global_position = Vector2(vp.x * 0.5, vp.y * 0.5)


func _close() -> void:
	EventBus.dialogue_closed.emit()
	queue_free()


func _on_continue() -> void:
	if _typing:
		_skip_typewriter()
	elif _waiting_for_click:
		if branch_container.visible:
			return
		_advance_dialogue()


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
		_waiting_for_click = true
		continue_btn.text = "结束"
		continue_btn.show()
		return
	_current_node_id = start_id
	_show_node(node)


func _show_node(node: Dictionary) -> void:
	_execute_actions(node.get("actions", []))
	var speaker_id = node.get("speaker", "")
	if not speaker_id.is_empty():
		_set_speaker_by_id(speaker_id)
	_full_text = node.get("text", "")
	var options = node.get("options", [])
	if options.size() > 0:
		_show_branches(options)
		return
	_clear_branches()
	text_label.text = _full_text
	_start_typewriter()


func _start_typewriter() -> void:
	_typing = true
	_text_complete = false
	_type_index = 0
	_type_timer = 0.0
	text_label.visible_characters = 0
	continue_btn.hide()


func _skip_typewriter() -> void:
	_typing = false
	_text_complete = true
	text_label.visible_characters = -1
	_try_show_continue()


func _process(delta: float) -> void:
	if not _typing:
		return
	_type_timer += delta
	var steps := 0
	while _type_timer >= TYPE_SPEED and _typing and steps < 3:
		steps += 1
		_type_timer -= TYPE_SPEED
		_type_index += 1
		text_label.visible_characters = _type_index
		if _type_index >= _full_text.length():
			_typing = false
			_text_complete = true
			_try_show_continue()
			return


func _try_show_continue() -> void:
	var node = _get_node(_current_node_id)
	if node.is_empty():
		return
	var next_id = node.get("next_node_id", "")
	if next_id.is_empty() and node.get("options", []).size() == 0:
		_waiting_for_click = true
		continue_btn.text = "结束"
		continue_btn.show()
		return
	if node.get("options", []).size() > 0:
		_waiting_for_click = false
		return
	_waiting_for_click = true
	continue_btn.text = "▼"
	continue_btn.show()


func _advance_dialogue() -> void:
	continue_btn.hide()
	var node = _get_node(_current_node_id)
	if node.is_empty():
		_close()
		return
	var next_id = node.get("next_node_id", "")
	if next_id.is_empty():
		_close()
		return
	var next_node = _get_node(next_id)
	if next_node.is_empty():
		_close()
		return
	_current_node_id = next_id
	_waiting_for_click = false
	_text_complete = false
	_show_node(next_node)


func _set_speaker_by_id(card_id: String) -> void:
	if card_id.is_empty():
		portrait_rect.texture = null
		portrait_margin.hide()
		speaker_label.text = _current_speaker_name
		speaker_label.modulate = Color(0.5, 0.8, 1, 1)
		_speaker_card = null
		return
	var card = EventBus.get_card_by_id(card_id)
	if card and card.card_data:
		_speaker_card = card
		speaker_label.text = card.card_data.card_name
		if card.card_data.art:
			portrait_rect.texture = card.card_data.art
			portrait_margin.show()
		else:
			portrait_margin.hide()
		speaker_label.modulate = card.card_data.border_color if card.card_data.border_color != Color.BLACK else Color(0.5, 0.8, 1, 1)


func _on_branch_selected(option_data: Dictionary) -> void:
	var next_id = option_data.get("next_node_id", "")
	if next_id.is_empty():
		_clear_branches()
		_waiting_for_click = true
		continue_btn.text = "结束"
		continue_btn.show()
		return
	var next_node = _get_node(next_id)
	if next_node.is_empty():
		_clear_branches()
		_waiting_for_click = true
		continue_btn.text = "结束"
		continue_btn.show()
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
	return Vector2(randi_range(200, 600), randi_range(300, 600))


func _show_branches(options: Array) -> void:
	_clear_branches()
	text_label.hide()
	continue_btn.hide()
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
	text_label.show()


func _get_node(node_id: String) -> Dictionary:
	return _dialogue_data.get(node_id, {})


func _load_json(path: String) -> Dictionary:
	if path.is_empty():
		return {}
	var text = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_warning("DialoguePanel: empty file '%s'" % path)
		return {}
	var json = JSON.parse_string(text)
	if not json is Dictionary:
		push_warning("DialoguePanel: '%s' is not a valid JSON object" % path)
		return {}
	var errors = _validate_dialogue(json, path)
	for e in errors:
		push_warning(e)
	return json


static func _validate_dialogue(data: Dictionary, path: String) -> Array[String]:
	var errors: Array[String] = []
	var tag = "[Dialogue %s]" % path.get_file()

	# 1. Check start node exists
	if not data.has("start"):
		errors.append("%s Missing 'start' node" % tag)

	# Collect all node IDs (everything except "topics")
	var node_ids: Dictionary = {}
	for key in data:
		if key == "topics":
			continue
		node_ids[key] = true

	# 2. Validate topic references
	var topics = data.get("topics", {})
	for topic_key in topics:
		var target = topics[topic_key]
		if not node_ids.has(target):
			errors.append("%s topics['%s'] → '%s' not found" % [tag, topic_key, target])

	# 3. Validate each node
	var referenced: Dictionary = {"start": true}
	for node_id in node_ids:
		var node = data[node_id]
		if not node is Dictionary:
			errors.append("%s Node '%s' is not an object" % [tag, node_id])
			continue
		# text field
		if not node.has("text") or node.get("text", "") == "":
			errors.append("%s Node '%s' missing 'text'" % [tag, node_id])
		# next_node_id reference
		var next_id = node.get("next_node_id", "")
		if not next_id.is_empty():
			referenced[next_id] = true
			if not node_ids.has(next_id):
				errors.append("%s Node '%s' → next '%s' not found" % [tag, node_id, next_id])
		# options references
		var options = node.get("options", [])
		for opt in options:
			var opt_next = opt.get("next_node_id", "")
			if opt_next.is_empty():
				errors.append("%s Node '%s' option '%s' has no next_node_id" % [tag, node_id, opt.get("text", "?")])
			elif not node_ids.has(opt_next):
				errors.append("%s Node '%s' option '%s' → '%s' not found" % [tag, node_id, opt.get("text", "?"), opt_next])
			else:
				referenced[opt_next] = true
		# actions validation
		var actions = node.get("actions", [])
		for action in actions:
			var type = action.get("type", "")
			match type:
				"favorability":
					if action.get("target_id", "").is_empty():
						errors.append("%s Node '%s' favorability action missing target_id" % [tag, node_id])
				"spawn_card":
					if action.get("card_id", "").is_empty():
						errors.append("%s Node '%s' spawn_card action missing card_id" % [tag, node_id])
				_:
					if not type.is_empty():
						errors.append("%s Node '%s' unknown action type '%s'" % [tag, node_id, type])

	# 4. Warn about unreachable nodes
	for node_id in node_ids:
		if not referenced.has(node_id):
			errors.append("%s Node '%s' is unreachable" % [tag, node_id])

	return errors
