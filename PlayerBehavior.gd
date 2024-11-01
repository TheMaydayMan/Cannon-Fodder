extends Node

func _ready() -> void:
	var castleLocation = get_tree().current_scene.get_node(name + "CastleLocation")
	var castle = preload("res://Castles/Examples/ExampleCastleA.tscn").instantiate()
	castle.global_transform = castleLocation.global_transform
	if castleLocation.flipped:
		pass ## TODO
	get_tree().current_scene.add_child(castle)
