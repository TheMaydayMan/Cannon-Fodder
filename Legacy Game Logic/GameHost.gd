extends Node

var singleplayer = true
var players = []
var active_player = 0

var resolving_round = false
var resolutions_required = 0
var resolutions_recieved = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for autoload in get_tree().root.get_children():
		if autoload is PlayerBehavior:
			players.append(autoload)
	
	var resolutions = []
	for p in players:
		resolutions.append_array(p.get_action_resolution_signals())
	for r in resolutions:
		r.connect(move_to_next_round)
	
	new_round()

func new_round() -> void:
	resolving_round = false
	active_player = 0
	for p in players: p.reset_actions()
	players[active_player].change_turns(true)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("continue"):
		next_player()

func next_player() -> void:
	players[active_player].change_turns(false)
	if active_player == players.size() - 1:
		if not resolving_round:
			resolve_round()
	else:
		active_player += 1
		players[active_player].change_turns(true)

func resolve_round() -> void:
	resolving_round = true
	resolutions_required = 0
	for p in players:
		p.trigger_actions()
		resolutions_required += p.get_action_resolution_signals().size()
	resolutions_recieved = 0

func move_to_next_round() -> void:
	resolutions_recieved += 1
	if resolutions_required == resolutions_recieved:
		new_round()
