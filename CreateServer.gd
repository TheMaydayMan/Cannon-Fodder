extends HBoxContainer

func _on_host_button_pressed() -> void:
	Global.max_players = int(get_node("MaxPlayers").text)
	Global.port = int(get_node("Port").text)
	get_tree().change_scene_to_file("res://Server.tscn")
