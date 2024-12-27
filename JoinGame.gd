extends HBoxContainer

func _on_join_button_pressed() -> void:
	Global.address = get_node("Address").text
	Global.port = int(get_node("Port").text)
	get_tree().change_scene_to_file("res://ClientGame.tscn")
