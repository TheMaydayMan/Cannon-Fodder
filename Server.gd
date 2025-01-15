extends Node2D

var lobby_clients = []
var playing_clients = []

func _ready() -> void:
	# Create the server connection
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(Global.port, Global.max_players)
	multiplayer.multiplayer_peer = peer
	
	multiplayer.peer_connected.connect(_on_peer_connected)

func _on_peer_connected(peer_id: int) -> void:
	lobby_clients.append(peer_id)
	if lobby_clients.size() > 1: # Start a game when two clients are available
		create_new_game(lobby_clients[0], lobby_clients[1])
	update_server_label()

func create_new_game(peer_1_id: int, peer_2_id: int) -> void:
	# Define game state
	var game = Dictionary()
	game["Player1"] = peer_1_id
	game["Player2"] = peer_2_id
	playing_clients.append(game)
	lobby_clients.pop_at(lobby_clients.find(peer_1_id))
	lobby_clients.pop_at(lobby_clients.find(peer_2_id))
	
	# Initialize game world
	var game_viewport = SubViewport.new()
	game_viewport.size = Vector2(1280, 720)
	add_child(game_viewport)
	game["Viewport"] = game_viewport
	
	# Load the game world
	var level_path = "res://Legacy Game Logic/TestFightScene.tscn"
	var castle_path = "res://Castles/Examples/ExampleCastleA.tscn"
	# For server
	Global.load_new_game(level_path, game["Player1"], game["Player2"], castle_path, castle_path, self, game["Viewport"])
	# For clients
	Global.load_new_client_game.rpc_id(game["Player1"], level_path, game["Player1"], game["Player2"], castle_path, castle_path)
	Global.load_new_client_game.rpc_id(game["Player2"], level_path, game["Player1"], game["Player2"], castle_path, castle_path)
	
	# Start up the game
	game["Player1Actions"] = null
	game["Player2Actions"] = null
	game["WaitingForActions"] = true
	Global.start_client_game.rpc_id(game["Player1"], game["Player2"])
	Global.start_client_game.rpc_id(game["Player2"], game["Player1"])

# Get actions from a client
func recieve_actions(id: int, actions: Dictionary) -> void:
	var game = game_from_player_id(id)
	if game.size() > 0: # Make sure the client is a legit player
		# Save the actions
		var player = "Player1" if game["Player1"] == id else "Player2"
		game[player + "Actions"] = actions
		
		# Notify opponent that the player locked in
		var opponent = "Player2" if game["Player1"] == id else "Player1"
		Global.alert_opponent_lock.rpc_id(game[opponent])
		
		# Resolve actions if all have been sent
		if game["Player1Actions"] and game["Player2Actions"]:
			resolve_actions(game)

func resolve_actions(game: Dictionary) -> void:
	# Send both clients the actions that will be resolved
	var player_1_actions = var_to_bytes(game["Player1Actions"])
	var player_2_actions = var_to_bytes(game["Player2Actions"])
	Global.send_clients_locked_actions.rpc_id(game["Player1"], player_1_actions, player_2_actions)
	Global.send_clients_locked_actions.rpc_id(game["Player2"], player_2_actions, player_1_actions)
	
	# Configure own actors
	Global.configure_actors(game["Player1Actions"], game["Viewport"].get_child(0), true)
	Global.configure_actors(game["Player2Actions"], game["Viewport"].get_child(0), true)
	print("All server actors configured")
	
	# Resolve
	await get_tree().create_timer(1).timeout
	Global.resolve_all_actors(game["Viewport"].get_child(0))

# Utility
func game_from_player_id(id: int) -> Dictionary:
	for game in playing_clients:
		if game["Player1"] == id or game["Player2"] == id:
			return game
	return Dictionary()

# Change the text in the server window
func update_server_label() -> void:
	get_node("ServerLabel").text = str(lobby_clients.size()) + " clients in lobby\n"
	get_node("ServerLabel").text += str(playing_clients.size() * 2) + " clients playing"
