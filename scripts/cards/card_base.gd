extends Control

var card_data: CardData : set = set_card_data
var spawn_source: Control

var drag_offset := Vector2.ZERO
var is_dragging := false
var _container: Control
var _drag_start_pos := Vector2.ZERO
var _has_moved := false
var _prev_z_index := 0
var _pressed_self := false
var _was_in_staging := false

const STACK_OFFSET := Vector2(0, 30)
const MIN_DRAG_DISTANCE := 10.0
const STAGING_X_START := 300
const BOARD_MIN_X := 280
const SIDEBAR_GAP := 20

@onready var hover_overlay: ColorRect = $HoverOverlay

var _hover_tween: Tween
var _press_tween: Tween
var _is_hovered := false

var _staging_mode := false
var _CardSceneScript = load("res://scripts/cards/card_scene.gd")

func _ready():
	_container = EventBus.get_card_container()
	add_to_group("cards")
	EventBus.register_card(self)
	EventBus.favorability_changed.connect(_on_favorability_changed)
	if card_data:
		$Visual.refresh(card_data)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_try_start_corruption()

func _enter_tree():
	if card_data == null or _container == null:
		return
	EventBus.register_card(self)
	$Visual.refresh(card_data)

func _exit_tree():
	EventBus.unregister_card(self)


# ── Hover / Press Tween ──

func _on_mouse_entered():
	_is_hovered = true
	if not is_inside_tree() or not hover_overlay:
		return
	if is_dragging:
		return
	_kill_tween(_hover_tween)
	_hover_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.12)
	_hover_tween.parallel().tween_property(hover_overlay, "color:a", 0.12, 0.12)

func _on_mouse_exited():
	_is_hovered = false
	if not is_inside_tree() or not hover_overlay:
		return
	_kill_tween(_hover_tween)
	if is_dragging:
		return
	_hover_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(self, "scale", Vector2.ONE, 0.1)
	_hover_tween.parallel().tween_property(hover_overlay, "color:a", 0.0, 0.1)

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


# ── Setup ──

func setup(data: CardData) -> void:
	card_data = data
	_try_start_corruption()

func set_card_data(data: CardData) -> void:
	card_data = data
	if is_node_ready():
		$Visual.refresh(data)
		_try_start_corruption()


# ── Favorability ──

func _on_favorability_changed(card_id: String, old_val: int, new_val: int, delta: int) -> void:
	if card_data and card_data.card_id == card_id:
		if card_data.card_type == CardData.CardType.CHAR:
			$Visual.update_favor_display(new_val, card_data.max_favorability)
		_show_heart_popup(delta)

func _show_heart_popup(delta: int) -> void:
	var heart = Label.new()
	heart.text = "❤ +%d" % delta
	heart.add_theme_font_size_override("font_size", 20)
	heart.modulate = Color(1, 0.2, 0.2, 1)
	heart.position = Vector2(size.x / 2 - 30, -40)
	heart.z_index = 200
	add_child(heart)
	var t = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(heart, "position:y", -80, 0.6)
	t.parallel().tween_property(heart, "modulate:a", 0.0, 0.6)
	t.tween_callback(heart.queue_free)


# ── Corruption ──

func _try_start_corruption() -> void:
	if is_node_ready() and card_data and card_data.corruption_time > 0:
		$Corruption.start(card_data)


# ── Drag & Stack ──

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		if _staging_mode:
			return
		if card_data and card_data.card_type == CardData.CardType.SCENE:
			if get_script() != _CardSceneScript:
				set_script(_CardSceneScript)
			SceneDesktopManager.enter_scene(self)
			return
		if card_data and card_data.dialogue_config:
			EventBus.dialogue_requested.emit(card_data.dialogue_config, card_data.card_name, "", self, null)
			return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_pressed_self = true
		_drag_start_pos = get_global_mouse_position()
		_press_effect()

func _input(event):
	if get_parent() != _container:
		return
	if not _pressed_self:
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
		var saved_gp = global_position
		var saved_mouse = get_global_mouse_position()
		reparent(_container)
		global_position = saved_gp
		drag_offset = saved_mouse - saved_gp
		EventBus.card_broken.emit(self)
	else:
		drag_offset = get_global_mouse_position() - global_position
	set_staging_mode(false)
	if global_position.x < BOARD_MIN_X:
		global_position.x = BOARD_MIN_X + SIDEBAR_GAP
	if global_position.y >= CardManager.STAGING_Y:
		global_position.y = CardManager.STAGING_Y - size.y - 20
	is_dragging = true
	_has_moved = false
	_drag_start_pos = global_position
	_prev_z_index = z_index
	z_index = 100
	scale = Vector2.ONE
	hover_overlay.color.a = 0.0
	$Corruption.pause()
	EventBus.card_drag_started.emit(self)

func _start_drag():
	_was_in_staging = global_position.y >= CardManager.STAGING_Y
	start_drag()

func _end_drag():
	if not is_dragging:
		return
	is_dragging = false
	z_index = _prev_z_index
	scale = Vector2.ONE
	hover_overlay.color.a = 0.0
	$Corruption.resume()
	EventBus.card_drag_ended.emit(self)
	if _has_moved:
		if _was_in_staging and global_position.y >= CardManager.STAGING_Y - 60:
			_snap_to_staging()
		elif not _was_in_staging and global_position.y >= CardManager.STAGING_Y:
			_snap_to_staging()
		elif _was_in_staging:
			_board_from_staging()
		else:
			_try_stack()
		if get_parent() == _container:
			if global_position.y < CardManager.STAGING_Y:
				var overlap = (global_position.y + size.y) - CardManager.STAGING_Y
				if overlap > -10:
					global_position.y = CardManager.STAGING_Y - size.y - 10
			if global_position.x < BOARD_MIN_X:
				var eject_x = BOARD_MIN_X + SIDEBAR_GAP
				var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				tween.tween_property(self, "global_position:x", eject_x, 0.12)
	else:
		_release_effect()

func _board_from_staging() -> void:
	var card_bottom = global_position.y + size.y
	if card_bottom >= CardManager.STAGING_Y - 20:
		global_position.y = CardManager.STAGING_Y - size.y - 20
	if global_position.x < BOARD_MIN_X:
		global_position.x = BOARD_MIN_X + SIDEBAR_GAP
	if global_position.y < 0:
		_snap_to_staging()
		return
	_try_stack()


# ── Staging Area ──

func set_staging_mode(enabled: bool) -> void:
	_staging_mode = enabled
	if enabled:
		$Corruption.pause()

func arrange_staging(x: float) -> void:
	z_index = 0
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", Vector2(x, CardManager.STAGING_Y + 20), 0.12)

func _snap_to_staging() -> void:
	if card_data and card_data.corruption_time > 0:
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "global_position", Vector2(global_position.x, CardManager.STAGING_Y - 300), 0.15)
		_release_effect()
		return
	EventBus.staging_arrange_requested.emit(self, _was_in_staging)
	_release_effect()

func _try_stack():
	if global_position.y >= CardManager.STAGING_Y:
		return
	var my_rect = Rect2(global_position, size)
	for card in _container.get_children():
		if card == self or not card.visible or card.global_position.y >= CardManager.STAGING_Y:
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
