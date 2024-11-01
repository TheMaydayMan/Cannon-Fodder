extends Node2D

# After all children have finished their work (hence the triple deferral), reparent them to the scene root.
func _ready() -> void:
	reparent_children.call_deferred.call_deferred.call_deferred()

func reparent_children() -> void:
	for c in get_children():
		c.reparent(get_parent())
