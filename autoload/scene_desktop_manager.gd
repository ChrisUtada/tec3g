extends Node

var _active_scene_card: Control = null
var _hidden_container: Node = null
var _main_desktop_cards: Array[Control] = []
var _scene_desktop_cards: Array[Control] = []
var _main_bg_color := Color.BLACK
var _scene_bg_overlay: ColorRect = null
var _scene_card_btn: Button = null
var _move_all_btn: Button = null
var _hidden_nodes: Array[Node] = []
var _layout_loaded := false


func _ready():
	_hidden_container = Node.new()
	_hidden_container.name = "HiddenCards"


func is_in_scene() -> bool:
	return _active_scene_card != null


func enter_scene(scene_card: Control) -> void:
	if not scene_card or not scene_card.card_data:
		return
	if not scene_card.card_data.layout_scene:
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

	_cleanup_card_manager_state()

	_save_main_desktop(container)
	_restore_scene_desktop(container)
	_load_scene_layout(container)
	_add_scene_bg_overlay(game_board)
	_hide_ui(game_board)
	_add_scene_header(game_board)

	_show_scene_banner(game_board)

	EventBus.scene_desktop_entered.emit(scene_card.card_data)


func exit_scene() -> void:
	if not _active_scene_card:
		return

	var container = EventBus.get_card_container()
	var game_board = get_tree().current_scene.get_node_or_null("GameBoard")

	for group in ["dialogue_panel"]:
		for node in get_tree().get_nodes_in_group(group):
			if is_instance_valid(node):
				node.queue_free()

	_save_scene_desktop(container)
	_restore_main_desktop(container)
	_remove_scene_bg_overlay()
	_restore_ui()
	_remove_scene_header()
	_remove_scene_banner(game_board)

	if game_board:
		var bg = game_board.get_node_or_null("Background")
		if bg:
			bg.color = _main_bg_color

	_active_scene_card = null
	EventBus.scene_desktop_exited.emit()


func _cleanup_card_manager_state() -> void:
	CardManager.cancel_all_pending()


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
	var art_path = "res://assets/scenes/%s.png" % _active_scene_card.card_data.card_id
	if ResourceLoader.exists(art_path):
		var tex = TextureRect.new()
		tex.texture = load(art_path)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.anchors_preset = Control.PRESET_FULL_RECT
		tex.mouse_filter = Control.MOUSE_FILTER_PASS
		_scene_bg_overlay.add_child(tex)
	game_board.add_child(_scene_bg_overlay)
	var bg = game_board.get_node_or_null("Background")
	var insert_idx = bg.get_index() + 1 if bg else 1
	game_board.move_child(_scene_bg_overlay, insert_idx)


func _remove_scene_bg_overlay() -> void:
	if _scene_bg_overlay and _scene_bg_overlay.is_inside_tree():
		_scene_bg_overlay.queue_free()
	_scene_bg_overlay = null


func _hide_ui(game_board: Control) -> void:
	for group in ["dialogue_panel"]:
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
	var all_cards: Array[Control] = []
	var to_check: Array[Node] = card.get_children()
	while to_check.size() > 0:
		var c = to_check.pop_back()
		if c is Control and c.is_in_group("cards"):
			all_cards.append(c)
			to_check.append_array(c.get_children())
	var saved_pos = card.global_position
	card.reparent(bar)
	card.global_position = Vector2(saved_pos.x, CardManager.STAGING_Y + 20)
	for c in all_cards:
		saved_pos = c.global_position
		c.reparent(bar)
		c.global_position = Vector2(saved_pos.x, CardManager.STAGING_Y + 20)


func _load_scene_layout(container: Control) -> void:
	if _layout_loaded:
		return
	var layout_packed = _active_scene_card.card_data.layout_scene
	if not layout_packed:
		return
	_layout_loaded = true
	var layout = layout_packed.instantiate()
	for child in layout.get_children():
		var ph := child as CardPlaceholder
		if not ph or not ph.card_data:
			continue
		CardManager.spawn_card(ph.card_data, ph.global_position)
	layout.queue_free()


func _show_scene_banner(game_board: Control) -> void:
	var data = _active_scene_card.card_data
	if not data:
		return

	var banner = Panel.new()
	banner.name = "SceneBanner"
	banner.anchor_left = 0.0
	banner.anchor_top = 0.0
	banner.anchor_right = 0.0
	banner.anchor_bottom = 0.0
	banner.size = Vector2(600, 100)
	banner.position = Vector2(-620, 100)
	banner.mouse_filter = Control.MOUSE_FILTER_PASS

	var border = StyleBoxFlat.new()
	border.bg_color = Color(0.1, 0.1, 0.15, 0.85)
	border.border_color = data.border_color
	border.border_width_left = 4
	border.border_width_right = 0
	border.border_width_top = 0
	border.border_width_bottom = 2
	border.corner_radius_top_right = 6
	border.corner_radius_bottom_right = 6
	banner.add_theme_stylebox_override("panel", border)

	var title = Label.new()
	title.text = data.card_name
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", data.border_color)
	title.position = Vector2(16, 12)
	title.size = Vector2(568, 30)
	banner.add_child(title)

	var desc = Label.new()
	desc.text = data.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	desc.position = Vector2(16, 46)
	desc.size = Vector2(568, 50)
	banner.add_child(desc)

	game_board.add_child(banner)

	var tween = create_tween().bind_node(banner).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(banner, "position:x", 10, 0.5)
	tween.tween_interval(3.5)
	tween.tween_property(banner, "modulate:a", 0.0, 0.4)
	tween.tween_callback(banner.queue_free)


func _remove_scene_header() -> void:
	if _scene_card_btn and _scene_card_btn.is_inside_tree():
		_scene_card_btn.queue_free()
	_scene_card_btn = null
	if _move_all_btn and _move_all_btn.is_inside_tree():
		_move_all_btn.queue_free()
	_move_all_btn = null


func _remove_scene_banner(game_board: Control) -> void:
	if not game_board:
		return
	var banner = game_board.get_node_or_null("SceneBanner")
	if banner:
		banner.queue_free()


func _input(event):
	if event.is_action_pressed("ui_cancel") and is_in_scene():
		exit_scene()
		get_viewport().set_input_as_handled()
