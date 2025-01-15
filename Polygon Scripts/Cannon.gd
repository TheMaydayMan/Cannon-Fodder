extends PolyActor

@export var max_launch_power : float
@export var max_power_distance : float

@export var cannonball_radius : float
@export var blast_radius : float
@export var cannonball_color : Color

func _process(delta: float) -> void:
	super(delta)
	queue_redraw()

func _draw() -> void:
	if selected:
		draw_trajectory(get_global_mouse_position())
	elif config["AimPos"]:
		draw_trajectory(config["AimPos"])

func draw_trajectory(pos: Vector2) -> void:
	var origin_offset = polygon_centroid(global_to_local_polygon(global_polygon()))
	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity_vector") * ProjectSettings.get_setting("physics/2d/default_gravity")
	var angle = polygon_centroid(global_polygon()).angle_to_point(pos)
	var dot_pos = launch_pos(angle) + origin_offset
	var dot_vel = launch_vel(gravity, pos - origin_offset)
	var delta = 0.1
	for i in 10:
		draw_circle(dot_pos, 3, Color.WHITE)
		dot_vel += gravity * delta
		dot_pos += dot_vel * delta

func launch_pos(angle: float) -> Vector2:
	return (Vector2.RIGHT * 18).rotated(angle)

func launch_vel(gravity: Vector2, pos: Vector2) -> Vector2:
	return (pos - global_position) - (0.5 * gravity)

func launch_power(pos: Vector2) -> float:
	return min(polygon_centroid(global_polygon()).distance_to(pos), max_power_distance) / max_power_distance * max_launch_power

func deselect() -> void:
	super()

func configure() -> void:
	super()
	config["AimPos"] = get_global_mouse_position()

func resolve():
	super()
	
	if config["AimPos"]:
		# Figure out velocity
		var origin_offset = polygon_centroid(global_to_local_polygon(global_polygon()))
		var gravity = ProjectSettings.get_setting("physics/2d/default_gravity_vector") * ProjectSettings.get_setting("physics/2d/default_gravity")
		var angle = polygon_centroid(global_polygon()).angle_to_point(config["AimPos"])
		var shot_pos = launch_pos(angle) + origin_offset
		var shot_vel = launch_vel(gravity, config["AimPos"] - origin_offset)
		
		# Create cannonball
		var cannonball_body = RigidBody2D.new()
		cannonball_body.global_position = shot_pos + global_position + (Vector2.RIGHT.rotated(angle) * cannonball_radius)
		cannonball_body.linear_velocity = shot_vel
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
		
		# Set to explode
		var explode = func explode(_other: Node) -> void:
			var hole = PolyHole.new()
			hole.global_transform = cannonball_body.global_transform
			hole.polygon = generate_polygon(24, blast_radius)
			hole.color = Color.TRANSPARENT
			hole.name = name
			body.get_parent().add_child(hole)
			cannonball_body.queue_free()
			resolved.emit()
		cannonball_body.body_entered.connect(explode)
		
		# Auto-resolve after five seconds on miss
		await get_tree().create_timer(5).timeout
		if is_instance_valid(cannonball_body):
			cannonball_body.queue_free()
			resolved.emit()
	else:
		resolved.emit()

func reset():
	super()
	config["AimPos"] = null


func generate_polygon(sides: int, radius: float) -> PackedVector2Array:
	var points = PackedVector2Array()
	var angle_increment = 2 * PI / sides
	
	for i in range(sides):
		var angle = angle_increment * i
		var x = radius * cos(angle)
		var y = radius * sin(angle)
		points.append(Vector2(x, y))
	
	return points
