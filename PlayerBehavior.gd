extends Node
class_name PlayerBehavior

var castle_location
var castle
var action_polies = []

var my_turn = false

func _ready() -> void:
	castle_location = get_tree().current_scene.get_node(name + "CastleLocation")
	castle = preload("res://Castles/Examples/ExampleCastleA.tscn").instantiate()
	
	if castle_location.flipped:
		for c in castle.get_children():
			var new_poly = PackedVector2Array()
			for p in c.polygon:
				new_poly.append(Vector2(-p.x - c.position.x*2, p.y))
			new_poly.reverse() # Only counterclockwise polygons work
			c.polygon = new_poly
	
	castle.global_transform = castle_location.global_transform
	get_tree().current_scene.add_child(castle)
	get_action_polies(castle, action_polies)
	reparent_castle_children.call_deferred.call_deferred.call_deferred()

func get_action_polies(node: Node, result: Array) -> void:
	if node is ActionPolyBody:
		result.push_back(node)
		node.on_selected.connect(func x(): for a in action_polies: if is_instance_valid(a): a.selectable = false)
		node.on_deselected.connect(func x(): for a in action_polies: if is_instance_valid(a): a.selectable = true)
	for child in node.get_children():
		get_action_polies(child, result)

func reparent_castle_children() -> void:
	for c in castle.get_children():
		c.reparent(get_tree().current_scene)


func change_turns(now_my_turn: bool):
	my_turn = now_my_turn
	for a in action_polies:
		if is_instance_valid(a):
			a.selectable = my_turn
			a.get_node("Outline").texture = preload("res://Visuals/DottedLine.png") if my_turn else null
		else:
			action_polies.erase(a)

func reset_actions() -> void:
	for a in action_polies: if is_instance_valid(a): a.configured = false

func trigger_actions() -> void:
	for a in action_polies: if is_instance_valid(a): a.trigger()

func get_action_resolution_signals() -> Array:
	var signals = []
	for a in action_polies: if is_instance_valid(a): signals.append(a.on_resolved)
	return signals
