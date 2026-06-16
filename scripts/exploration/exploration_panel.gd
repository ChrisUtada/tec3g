extends Control

var _config: ExplorationConfig
var _result: Dictionary = {}

@onready var panel: Control = $Panel
@onready var title_label: Label = $Panel/Title
@onready var desc_label: Label = $Panel/Desc
@onready var result_container: VBoxContainer = $Panel/ResultContainer
@onready var close_btn: Button = $Panel/CloseBtn


func _ready():
	visible = false
	close_btn.pressed.connect(close)
	panel.position = Vector2(1920, 0)
	PanelManager.register_exploration_panel(self)

func _input(event):
	if event.is_action_pressed("ui_cancel") and visible:
		close()

func get_panel_left() -> float:
	return panel.global_position.x

func open(config: ExplorationConfig, result: Dictionary) -> void:
	_config = config
	_result = result
	title_label.text = config.scene_name
	desc_label.text = config.scene_description
	_populate_results(result)
	visible = true
	_close_btn_focus()
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "position:x", 1920 - panel.size.x, 0.3)

func _close_btn_focus() -> void:
	await get_tree().process_frame
	close_btn.grab_focus()

func _populate_results(result: Dictionary) -> void:
	for child in result_container.get_children():
		child.queue_free()

	if result.get("rest", false):
		var lbl = Label.new()
		lbl.text = "休息完成，疲劳已消除。"
		lbl.add_theme_font_size_override("font_size", 18)
		result_container.add_child(lbl)
		close_btn.text = "关闭"
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

	close_btn.text = "关闭"

func close() -> void:
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(panel, "position:x", 1920, 0.25)
	await tween.finished
	visible = false
	EventBus.exploration_closed.emit()
