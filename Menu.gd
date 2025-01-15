extends Node2D

func _ready() -> void:
	var args = OS.get_cmdline_args()
	get_window().position = Vector2(int(args[1]), int(args[2]))
	if args[3] == "server":
		Global.max_players = int(get_node("VBoxContainer/Host/MaxPlayers").text)
		Global.port = int(get_node("VBoxContainer/Host/Port").text)
		get_tree().change_scene_to_file.call_deferred("res://Server.tscn")
	else:
		Global.address = get_node("VBoxContainer/Join/Address").text
		Global.port = int(get_node("VBoxContainer/Join/Port").text)
		get_tree().change_scene_to_file.call_deferred("res://ClientGame.tscn")
