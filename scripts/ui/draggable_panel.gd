extends Control

var _dragging := false
var _drag_offset := Vector2.ZERO

func _get_content_panel() -> Control:
	return null

func _is_topmost_at_pos(global_pos: Vector2) -> bool:
	var parent = get_parent()
	if not parent:
		return true
	for i in range(parent.get_child_count() - 1, -1, -1):
		var c = parent.get_child(i)
		if c == self:
			return true
		if not c.visible:
			continue
		var rect: Rect2
		if c.has_method("_get_content_panel"):
			var cp = c._get_content_panel()
			if cp:
				rect = Rect2(cp.global_position, cp.size)
		elif "bg_panel" in c:
			var bp = c.get_node_or_null("BgPanel")
			if bp:
				rect = Rect2(bp.global_position, bp.size)
		else:
			continue
		if rect.has_point(global_pos):
			return false
	return true

func _input(event):
	var cp = _get_content_panel()
	if not cp:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not _dragging:
			var local = cp.get_local_mouse_position()
			if Rect2(Vector2.ZERO, cp.size).has_point(local) and _is_topmost_at_pos(get_global_mouse_position()):
				_dragging = true
				_drag_offset = get_global_mouse_position() - cp.global_position
		elif not event.pressed:
			_dragging = false
	if event is InputEventMouseMotion and _dragging:
		cp.global_position = get_global_mouse_position() - _drag_offset
	if event.is_action_pressed("ui_cancel") and visible:
		queue_free()
