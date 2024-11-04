extends PolyBody
class_name ActionPolyBody

var selected = false
var selectable = false	
var configured = false
signal on_selected
signal on_deselected

func _unhandled_input(event):
	if selectable:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if Geometry2D.is_point_in_polygon(get_local_mouse_position(), polygon):
				selected = true
				on_selected.emit()
	elif selected:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			configured = true
			selected = false
			on_deselected.emit()

func trigger():
	pass # This should be overrided by extenders
