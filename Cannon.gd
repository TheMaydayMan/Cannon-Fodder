extends PolyBody

@export var enabled : bool
@export var max_power : float
@export var aim_power_scale : float
@export var cannonball_radius : float
@export var blast_radius : float
@export var cannonball_color : Color
@export var aim_line_thickness : float

var centroid
var mouse_pos
var direction
var shot_start
var shot_velocity

func _ready() -> void:
	super()
	set_values()

func _process(delta: float) -> void:
	super(delta)
	if enabled:
		set_values()
		
		queue_redraw()

func set_values():
	centroid = polygon_centroid(global_polygon())
	mouse_pos = get_global_mouse_position()
	var mouse_angle = centroid.angle_to_point(mouse_pos)
	direction = Vector2.RIGHT.rotated(mouse_angle)
	
	var power = centroid.distance_to(mouse_pos)
	power = clamp(power, (1/aim_power_scale) + 18, (max_power / aim_power_scale) + 18) * aim_power_scale
	shot_start = centroid + direction * 18
	shot_velocity = power * direction

func _draw() -> void:
	super()
	if enabled:
		var gravity = ProjectSettings.get_setting("physics/2d/default_gravity_vector") * ProjectSettings.get_setting("physics/2d/default_gravity")
		
		for i in range(10):
			var t = i/40.0
			draw_circle((shot_velocity * t) + (0.5 * gravity * t * t) + (shot_start - global_position), 4, Color.WHITE)

func _unhandled_input(event):
	if enabled:
		if event is InputEventMouseButton:
			if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
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
					if is_instance_valid(cannonball_body):
						hole.global_transform = cannonball_body.global_transform
						hole.polygon = generate_polygon(24, blast_radius)
						hole.color = Color.TRANSPARENT
						hole.name = name
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

func v2_sqrt(v2: Vector2) -> Vector2:
	return Vector2(sqrt(v2.x), sqrt(v2.y))
