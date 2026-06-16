extends Control

var _config: ExplorationConfig
var _result: Dictionary = {}
var _dragging := false
var _drag_offset := Vector2.ZERO

@onready var content_panel: Panel = $ContentPanel
@onready var title_label: Label = $ContentPanel/Title
@onready var desc_label: Label = $ContentPanel/Desc
@onready var result_container: VBoxContainer = $ContentPanel/ResultContainer
@onready var close_btn: Button = $ContentPanel/CloseBtn


func _ready():
	close_btn.pressed.connect(_close)

func open(config: ExplorationConfig, result: Dictionary) -> void:
	_config = config
	_result = result
	title_label.text = config.scene_name
	desc_label.text = config.scene_description
	_populate_results(result)
	_center_and_resize()

func _center_and_resize() -> void:
	await get_tree().process_frame
	var vp = get_viewport().size
	var total_h = 0
	for child in result_container.get_children():
		total_h += child.size.y + 6
	var panel_h = mini(80 + total_h + 40, vp.y - 80)
	var panel_w = mini(400, vp.x - 80)
	content_panel.custom_minimum_size = Vector2(panel_w, panel_h)
	content_panel.size = Vector2(panel_w, panel_h)
	content_panel.position = Vector2((vp.x - panel_w) * 0.5, (vp.y - panel_h) * 0.5)

func _populate_results(result: Dictionary) -> void:
	for child in result_container.get_children():
		child.queue_free()

	if result.get("rest", false):
		var lbl = Label.new()
		lbl.text = "休息完成，疲劳已消除。"
		lbl.add_theme_font_size_override("font_size", 18)
		result_container.add_child(lbl)
		return

	var branch_name = result.get("branch_name", "")
	if not branch_name.is_empty():
		var lbl = Label.new()
		lbl.text = "触发分支: " + branch_name
		lbl.add_theme_font_size_override("font_size", 18)
		result_container.add_child(lbl)

	var drops = result.get("drops", [])
	if drops.size() > 0:
		var hdr = Label.new()
		hdr.text = "\n获得物品:"
		hdr.add_theme_font_size_override("font_size", 16)
		result_container.add_child(hdr)
		for d in drops:
			var item = Label.new()
			item.text = "  • " + d
			result_container.add_child(item)

	if result.get("fatigue", false):
		var f = Label.new()
		f.text = "\n获得了 [疲劳]"
		f.modulate = Color(1, 0.5, 0.5)
		result_container.add_child(f)

	if drops.is_empty() and not result.get("fatigue", false):
		var empty = Label.new()
		empty.text = "\n探索完成，但无所获。"
		result_container.add_child(empty)

func _close() -> void:
	queue_free()

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
