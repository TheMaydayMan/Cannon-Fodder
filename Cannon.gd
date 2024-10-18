extends PolyBody

@export var max_power : float
@export var aim_power_scale : float
@export var cannonball_radius : float
@export var blast_radius : float
@export var cannonball_color : Color

func _process(delta: float) -> void:
	super(delta)
	queue_redraw()

func _draw() -> void:
	super()
	var centroid = polygon_centroid(global_polygon())
	var mouse_pos = get_global_mouse_position()
	var mouse_angle = centroid.angle_to_point(mouse_pos)
	var direction = Vector2.RIGHT.rotated(mouse_angle)
	var distance = centroid.distance_to(mouse_pos)
	distance = clamp(distance, (1/aim_power_scale) + 18, (max_power / aim_power_scale) + 18)
	draw_line(centroid - global_position + direction * 18, centroid - global_position + direction * distance, Color.WHITE, 5)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var centroid = polygon_centroid(global_polygon())
			var mouse_pos = get_global_mouse_position()
			var mouse_angle = centroid.angle_to_point(mouse_pos)
			var direction = Vector2.RIGHT.rotated(mouse_angle)
			
			var power = centroid.distance_to(mouse_pos)
			power = clamp(power, (1/aim_power_scale) + 18, (max_power / aim_power_scale) + 18) * aim_power_scale
			var shot_start = centroid + direction * 18
			var shot_velocity = power * direction
			
			var cannonball_body = RigidBody2D.new()
			cannonball_body.global_position = shot_start + (direction * cannonball_radius)
			cannonball_body.linear_velocity = shot_velocity
			cannonball_body.contact_monitor = true
			cannonball_body.max_contacts_reported = 1
			var cannonball_collider = CollisionPolygon2D.new()
			cannonball_collider.polygon = generate_polygon(24, cannonball_radius)
			cannonball_body.add_child(cannonball_collider)
			var cannonball_visual = Polygon2D.new()
			cannonball_visual.polygon = cannonball_collider.polygon
			cannonball_visual.color = cannonball_color
			cannonball_collider.add_child(cannonball_visual)
			body.get_parent().add_child(cannonball_body)
			
			var explode = func explode(_other: Node) -> void:
				var hole = PolyHole.new()
				hole.global_transform = cannonball_body.global_transform
				hole.polygon = generate_polygon(24, blast_radius)
				hole.color = Color.TRANSPARENT
				body.get_parent().add_child(hole)
				cannonball_body.queue_free()
			cannonball_body.body_entered.connect(explode)

func generate_polygon(sides: int, radius: float) -> PackedVector2Array:
	var points = PackedVector2Array()
	var angle_increment = 2 * PI / sides
	
	for i in range(sides):
		var angle = angle_increment * i
		var x = radius * cos(angle)
		var y = radius * sin(angle)
		points.append(Vector2(x, y))
	
	return points
