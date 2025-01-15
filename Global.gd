extends Node

var address
var port
var max_players
var game_master

# Start client games
@rpc
func load_new_client_game(level_path: String, player_1_id: int, player_2_id: int, castle_1_path: String, castle_2_path: String):
	load_new_game(level_path, player_1_id, player_2_id, castle_1_path, castle_2_path, get_tree().current_scene, get_tree().current_scene)

func load_new_game(level_path: String, player_1_id: int, player_2_id: int, castle_1_path: String, castle_2_path: String, gm: Node, level_top: Node):
	game_master = gm
	var level = load(level_path).instantiate()
	level_top.add_child(level)
	spawn_castle("Player1CastleLocation", castle_1_path, level, player_1_id)
	spawn_castle("Player2CastleLocation", castle_2_path, level, player_2_id)
	print("Level hash: " + hash_game_paths(level))

func hash_game_paths(level_top: Node) -> String:
	var hash = [""]
	process_all_children(level_top, func(child):
		hash[0] = str(hash[0], to_generic_path(child, level_top))
		hash[0] = hash[0].sha256_text()
	)
	return hash[0 ]

@rpc
func start_client_game(opponent_id: int):
	game_master.start_game(opponent_id)

# Load castles
func spawn_castle(location: String, path: String, level: Node2D, id: int):
	var castle_location = level.get_node(location)
	var castle = load(path).instantiate()
	castle.name = str(id)
	
	process_all_children(castle, func(child):
		if child is PolyBody:
			child.name = str(id) + "-" + child.name
	)
	
	if castle_location.flipped:
		for c in castle.get_children():
			if c is Polygon2D:
				var new_poly = PackedVector2Array()
				for p in c.polygon:
					new_poly.append(Vector2(-p.x, p.y))
				new_poly.reverse() # Only counterclockwise polygons work
				c.polygon = new_poly
				c.position.x = -c.position.x
			else:
				pass
	
	castle.global_transform = castle_location.global_transform
	level.add_child(castle)
	(func():
		for c in castle.get_children():
			c.reparent(level)
	).call_deferred.call_deferred.call_deferred()


# Action resolving RPCs and utilities
@rpc("any_peer") # Actor configuaration from client to server
func send_server_actions(client_id: int, actions_bytes: PackedByteArray):
	game_master.recieve_actions(client_id, bytes_to_var(actions_bytes))

@rpc # Opponent lock in alert from server to client
func alert_opponent_lock():
	game_master.opponent_locked = true
	game_master.update_lock_in_text()

@rpc # Start resolution, bitch
func send_clients_locked_actions(own_actions_bytes: PackedByteArray, opponent_actions_bytes: PackedByteArray):
	configure_actors(bytes_to_var(own_actions_bytes), game_master.fight_scene, true)
	configure_actors(bytes_to_var(opponent_actions_bytes), game_master.fight_scene, true)
	print("All client actors configured")
	
	# Resolve
	await get_tree().create_timer(1).timeout
	Global.resolve_all_actors(game_master.fight_scene)

# Set the configuration of all the actors mentioned by their generic paths
func configure_actors(configuration: Dictionary, top: Node, lock_all: bool) -> void:
	for path in configuration:
		print(path)
		get_tree().root.get_node(from_generic_path(path, top)).config = configuration[path]

func resolve_all_actors(top: Node) -> void:
	process_all_children(top, func(actor):
		if actor is PolyActor:
			actor.resolve()
	)


# Trim parents off of paths
func to_generic_path(node: Node, top: Node) -> String:
	return str(node.get_path()).erase(0, str(top.get_path()).length())

func from_generic_path(path: String, top: Node) -> String:
	return str(top.get_path()) + path

# Utility to process all children recursively
func process_all_children(node: Node, operation: Callable) -> void:
		for child in node.get_children():
			operation.call(child)
			process_all_children(child, operation)
