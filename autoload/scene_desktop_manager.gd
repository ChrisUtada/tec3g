extends Node

var _active_scene_card: Control = null
var _active_config: ExplorationConfig = null
var _hidden_container: Node = null
var _main_desktop_cards: Array[Control] = []
var _scene_desktop_cards: Array[Control] = []
var _main_bg_color := Color.BLACK
var _scene_bg_overlay: ColorRect = null
var _scene_card_btn: Button = null
var _move_all_btn: Button = null
var _hidden_nodes: Array[Node] = []


func _ready():
	_hidden_container = Node.new()
	_hidden_container.name = "HiddenCards"


func is_in_scene() -> bool:
	return _active_scene_card != null


func enter_scene(scene_card: Control) -> void:
	if not scene_card or not scene_card.card_data:
		return
	var config = SceneConfigRegistry.get_config(scene_card.card_data.card_id)
	if config == null:
		return
	var scene = get_tree().current_scene
	if not scene:
		return

	var game_board = scene.get_node_or_null("GameBoard")
	if not game_board:
		return
	var container = EventBus.get_card_container()
	if not container:
		return

	var bg = game_board.get_node_or_null("Background")
	if bg:
		_main_bg_color = bg.color

	_active_scene_card = scene_card
	_active_config = config

	_cleanup_card_manager_state()

	_save_main_desktop(container)
	_restore_scene_desktop(container)
	_add_scene_bg_overlay(game_board)
	_hide_ui(game_board)
	_add_scene_header(game_board)

	EventBus.scene_desktop_entered.emit(config)


func exit_scene() -> void:
	if not _active_scene_card:
		return

	var container = EventBus.get_card_container()
	var game_board = get_tree().current_scene.get_node_or_null("GameBoard")

	for group in ["dialogue_panel", "exploration_panel"]:
		for node in get_tree().get_nodes_in_group(group):
			if is_instance_valid(node):
				node.queue_free()

	_save_scene_desktop(container)
	_restore_main_desktop(container)
	_remove_scene_bg_overlay()
	_restore_ui()
	_remove_scene_header()

	if game_board:
		var bg = game_board.get_node_or_null("Background")
		if bg:
			bg.color = _main_bg_color

	_active_scene_card = null
	_active_config = null
	EventBus.scene_desktop_exited.emit()


func _cleanup_card_manager_state() -> void:
	if CardManager.exploring and CardManager.combo_bar:
		CardManager.combo_bar.cancel()
	CardManager.combo_bar = null
	CardManager.combo_bottom = null
	CardManager.combo_top = null
	CardManager.exploring = false
	CardManager.dialogue_topic_card = null
	if CardManager.obs_bar:
		CardManager.obs_bar.cancel()
	CardManager.obs_bar = null
	CardManager.obs_target = null
	CardManager.obs_card = null


func _save_main_desktop(container: Control) -> void:
	_main_desktop_cards.clear()
	for child in container.get_children():
		if child is Control and child.is_in_group("cards"):
			if child.global_position.y >= CardManager.STAGING_Y:
				continue
			_main_desktop_cards.append(child)
			child.set_meta("_saved_pos", child.global_position)
			child.reparent(_hidden_container)


func _restore_main_desktop(container: Control) -> void:
	for card in _main_desktop_cards:
		if not is_instance_valid(card):
			continue
		var saved_pos = card.get_meta("_saved_pos", Vector2(500, 300))
		card.reparent(container)
		card.global_position = saved_pos
	_main_desktop_cards.clear()


func _restore_scene_desktop(container: Control) -> void:
	for card in _scene_desktop_cards:
		if not is_instance_valid(card):
			continue
		var saved_pos = card.get_meta("_saved_pos", Vector2(500, 300))
		card.reparent(container)
		card.global_position = saved_pos
	_scene_desktop_cards.clear()


func _save_scene_desktop(container: Control) -> void:
	_scene_desktop_cards.clear()
	for child in container.get_children():
		if child is Control and child.is_in_group("cards"):
			if child == _active_scene_card:
				continue
			if child.global_position.y >= CardManager.STAGING_Y:
				continue
			_scene_desktop_cards.append(child)
			child.set_meta("_saved_pos", child.global_position)
			child.reparent(_hidden_container)


func _add_scene_bg_overlay(game_board: Control) -> void:
	_scene_bg_overlay = ColorRect.new()
	_scene_bg_overlay.color = Color(0.08, 0.08, 0.12)
	_scene_bg_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_scene_bg_overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	var art_path = "res://assets/scenes/%s.png" % _active_config.scene_card_id
	if ResourceLoader.exists(art_path):
		var tex = TextureRect.new()
		tex.texture = load(art_path)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.anchors_preset = Control.PRESET_FULL_RECT
		tex.mouse_filter = Control.MOUSE_FILTER_PASS
		_scene_bg_overlay.add_child(tex)
	game_board.add_child(_scene_bg_overlay)
	game_board.move_child(_scene_bg_overlay, 1)


func _remove_scene_bg_overlay() -> void:
	if _scene_bg_overlay and _scene_bg_overlay.is_inside_tree():
		_scene_bg_overlay.queue_free()
	_scene_bg_overlay = null


func _hide_ui(game_board: Control) -> void:
	for group in ["dialogue_panel", "exploration_panel"]:
		for node in get_tree().get_nodes_in_group(group):
			if is_instance_valid(node):
				node.queue_free()

	_hidden_nodes = []
	for name in ["UI"]:
		var node = game_board.get_node_or_null(name)
		if node and node.visible:
			node.visible = false
			_hidden_nodes.append(node)


func _restore_ui() -> void:
	for node in _hidden_nodes:
		if is_instance_valid(node):
			node.visible = true
	_hidden_nodes.clear()


func _add_scene_header(game_board: Control) -> void:
	if _scene_card_btn and _scene_card_btn.is_inside_tree():
		return
	var name_str = _active_scene_card.card_data.card_name.trim_prefix("场景：")
	_scene_card_btn = Button.new()
	_scene_card_btn.text = "← 离开「%s」" % name_str
	_scene_card_btn.position = Vector2(300, 10)
	_scene_card_btn.pressed.connect(exit_scene)
	game_board.add_child(_scene_card_btn)

	_move_all_btn = Button.new()
	_move_all_btn.text = "全部移出"
	_move_all_btn.position = Vector2(300, 40)
	_move_all_btn.pressed.connect(_move_all_to_staging)
	game_board.add_child(_move_all_btn)


func _move_all_to_staging() -> void:
	var container = EventBus.get_card_container()
	if not container:
		return
	var bar = EventBus.get_staging_bar()
	if not bar:
		return
	for child in container.get_children():
		if child is Control and child.is_in_group("cards") and child != _active_scene_card and child.global_position.y < CardManager.STAGING_Y:
			_flatten_stack(child, bar)
	CardManager.arrange_all_staging()


func _flatten_stack(card: Control, bar: Control) -> void:
	var cards: Array[Control] = [card]
	var parent = card.get_parent()
	for i in range(card.get_child_count() - 1, -1, -1):
		var c = card.get_child(i)
		if c is Control and c.is_in_group("cards"):
			cards.append(c)
			c.reparent(parent)
	for c in cards:
		var saved_pos = c.global_position
		c.reparent(bar)
		c.global_position = Vector2(saved_pos.x, CardManager.STAGING_Y + 20)


func _remove_scene_header() -> void:
	if _scene_card_btn and _scene_card_btn.is_inside_tree():
		_scene_card_btn.queue_free()
	_scene_card_btn = null
	if _move_all_btn and _move_all_btn.is_inside_tree():
		_move_all_btn.queue_free()
	_move_all_btn = null


func _input(event):
	if event.is_action_pressed("ui_cancel") and is_in_scene():
		exit_scene()
		get_viewport().set_input_as_handled()
