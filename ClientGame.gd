extends Node2D

func _ready() -> void:
	# Connect to the server
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(Global.address, Global.port)
	multiplayer.multiplayer_peer = peer
