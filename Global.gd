extends Node

var address
var port
var max_players

@rpc
func load_new_game(level_path: String, castle_1_path: String, castle_2_path: String):
	var level = load(level_path).instantiate()
	get_tree().current_scene.add_child(level)
	spawn_castle("Player1CastleLocation", castle_1_path, level)
	spawn_castle("Player2CastleLocation", castle_2_path, level)

func spawn_castle(location: String, path: String, level: Node2D):
	var castle_location = level.get_node(location)
	var castle = load(path).instantiate()
	
	if castle_location.flipped:
		for c in castle.get_children():
			var new_poly = PackedVector2Array()
			for p in c.polygon:
				new_poly.append(Vector2(-p.x - c.position.x*2, p.y))
			new_poly.reverse() # Only counterclockwise polygons work
			c.polygon = new_poly
	
	castle.global_transform = castle_location.global_transform
	level.add_child(castle)
	(func():
		for c in castle.get_children():
			c.reparent(level)
	).call_deferred.call_deferred.call_deferred()
