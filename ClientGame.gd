extends Node2D

enum {LOBBY, ACTING, LOCKED, RESOLVING}
var game_state = LOBBY

var actors = []
var selected_actor_index = -1

var fight_scene
var game_ui

var castle
var opponent_id
var opponent_castle

var opponent_locked = false

var locked_actor_configurations = null

func _ready() -> void:
	# Connect to the server
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(Global.address, Global.port)
	multiplayer.multiplayer_peer = peer

func start_game(opp_id: int) -> void:
	# Set defaults
	opponent_id = opp_id
	game_state = ACTING
	fight_scene = get_tree().current_scene.get_child(0)
	
	# Identify castles
	castle = fight_scene.get_node(str(multiplayer.get_unique_id()))
	opponent_castle = fight_scene.get_node(str(opponent_id))
	
	# Define actors and set up UI
	load_actors()
	game_ui = preload("res://GameUI.tscn").instantiate()
	get_tree().current_scene.add_child(game_ui)
	game_ui.get_node("LockIn").pressed.connect(lock_in)

# Identify and remember all controlled PolyActors
func load_actors() -> void:
	Global.process_all_children(castle, func(child):
		if child is PolyActor:
			child.selectable = true
			actors.append(child)
	)

# Check for clicking on actors
func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			if selected_actor_index == -1: # Left click, select new actor
				for actor in actors:
					if Geometry2D.is_point_in_polygon(get_global_mouse_position(), actor.global_polygon()):
						selected_actor_index = actors.find(actor)
						actor.select()
						break
			else: # Left click, configure chosen actor
				actors[selected_actor_index].configure()
				selected_actor_index = -1
		elif event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
			if selected_actor_index != -1: # Right click, cancel current actor configuration
				actors[selected_actor_index].deselect()
				selected_actor_index = -1

# Send all actions to the server
func lock_in() -> void:
	if game_state == ACTING: # Can only do it once
		# Fetch configurations
		locked_actor_configurations = Dictionary()
		for actor in actors:
			locked_actor_configurations[Global.to_generic_path(actor, fight_scene)] = actor.config
		
		# Send configurations
		Global.send_server_actions.rpc_id(1, multiplayer.get_unique_id(), var_to_bytes(locked_actor_configurations))
		game_state = LOCKED
		update_lock_in_text()
	else: # Reset your configuration to show what you locked in with
		Global.configure_actors(locked_actor_configurations, self, false)

# Update the lock in UI
func update_lock_in_text() -> void:
	var sum = 0
	
	if game_state == LOCKED or game_state == RESOLVING:
		game_ui.get_node("LockIn").text = "Locked In"
		sum += 1
	else:
		game_ui.get_node("LockIn").text = "Lock In"
	
	if opponent_locked:
		sum += 1
	
	game_ui.get_node("PlayersRemaining").text = str(sum) + "/2 Players Locked"
