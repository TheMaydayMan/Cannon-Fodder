extends Node2D

@export_enum("Linear", "Sinusoidal") var animation_type : String
@export var animation_speed : float
@export var animation_magnitude : float

var offset = Vector2(0, 0)
var timer = 0

func _process(delta: float) -> void:
	if animation_type == "Linear":
		offset -= Vector2.ONE * delta * animation_speed
	elif animation_type == "Sinusoidal":
		timer += delta * animation_speed
	
	var polygons = []
	find_all_of_class(get_tree().current_scene, "Polygon2D", polygons)
	
	for polygon in polygons:
		if polygon.material and polygon.material is ShaderMaterial:
			if animation_type == "Linear":
				polygon.material.set_shader_parameter("offset", offset * Vector2.ONE)
			elif animation_type == "Sinusoidal":
				polygon.material.set_shader_parameter("offset", sin(timer) * animation_magnitude * Vector2.ONE)

func find_all_of_class(node: Node, class_name_str: String, result : Array) -> void:
	if node.is_class(class_name_str) :
		result.push_back(node)
	for child in node.get_children():
		find_all_of_class(child, class_name_str, result)
