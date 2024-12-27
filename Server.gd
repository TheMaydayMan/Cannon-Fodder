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
	var level = load(level_path).instantiate()
	game["Viewport"].add_child(level)
	Global.spawn_castle("Player1CastleLocation", castle_path, level)
	Global.spawn_castle("Player2CastleLocation", castle_path, level)
	# For clients
	Global.load_new_game.rpc_id(game["Player1"], level_path, castle_path, castle_path)
	Global.load_new_game.rpc_id(game["Player2"], level_path, castle_path, castle_path)

func update_server_label() -> void:
	get_node("ServerLabel").text = str(lobby_clients.size()) + " clients in lobby\n"
	get_node("ServerLabel").text += str(playing_clients.size() * 2) + " clients playing"
