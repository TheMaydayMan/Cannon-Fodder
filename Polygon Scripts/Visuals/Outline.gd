extends Line2D

func _ready() -> void:
	get_parent().polygon_changed.connect(update_line)

func update_line():
	points = get_parent().polygon
