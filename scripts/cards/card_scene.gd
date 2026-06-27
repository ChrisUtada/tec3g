extends "res://scripts/cards/card_base.gd"
class_name CardScene

var origin_scene: Control


func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		if _staging_mode:
			return
		SceneDesktopManager.enter_scene(self)
		return
	super._gui_input(event)
