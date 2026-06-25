extends Control

var _dragging := false
var _drag_offset := Vector2.ZERO

func _get_content_panel() -> Control:
	return null

func _input(event):
	var cp = _get_content_panel()
	if not cp:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not _dragging:
			var local = cp.get_local_mouse_position()
			if Rect2(Vector2.ZERO, cp.size).has_point(local):
				_dragging = true
				_drag_offset = get_global_mouse_position() - cp.global_position
		elif not event.pressed:
			_dragging = false
	if event is InputEventMouseMotion and _dragging:
		cp.global_position = get_global_mouse_position() - _drag_offset
	if event.is_action_pressed("ui_cancel") and visible:
		queue_free()
