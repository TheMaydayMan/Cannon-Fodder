extends Polygon2D
class_name PolyBody

## Density in kg per 10000 square units (100x100).
@export var density : float = 1
@export var fragile : bool
@export var draw_info : bool
@export var info_color : Color
@export var connections : Array[PolyBody]
@export var anchors : Array[Node2D]

var collider : CollisionPolygon2D
var body : RigidBody2D
var anchor_locations : PackedVector2Array

signal polygon_changed

### THE ONLY OBJECT THAT ROTATES SHOULD BE THE RIGIDBODY. EVERYTHING ELSE SHOULD HAVE ZERO LOCAL ROTATION.
func _ready() -> void:
	## Setup anchor locations
	if not get_parent() is CollisionPolygon2D:
		for anchor in anchors:
			anchor_locations.append(anchor.global_position)
	
	## Ready the collider
	if not get_parent() is CollisionPolygon2D:
		# Ensure rotation to be zero
		polygon = rotate_polygon(polygon, Vector2.ZERO, rotation)
		rotation = 0
		# Create new collider
		collider = CollisionPolygon2D.new()
		collider.polygon = polygon
		collider.position = position
		# Reparent to the collider
		get_parent().add_child.call_deferred(collider)
		reparent.call_deferred(collider)
	else: # This is a clone from a hole operation
		collider = get_parent()
		body = collider.get_parent()
	
	if false: # This code might just not be nessecary? It might have been causing some issues? idk
		for c in connections:
			if not is_instance_valid(c):
				connections.erase(c)
	
	## Group all connected polybodies under the same rigidbody
	if body == null:
		# This has not been assigned to a body, so check if any connections have
		for poly in connections:
			if poly.body != null:
				# If so, be assigned to that body
				body = poly.body
		if body == null:
			# If there is still no body, create a new one and assign self to it
			body = RigidBody2D.new()
			body.set_meta("IS_POLYBODY", true) # Other scripts will be able to tell this is a PolyBody body with this metadata
			body.freeze = true # Will be recalibrated later
			get_parent().add_child.call_deferred(body) # Since reparenting is deferred, this gets the will-be Collider's parent
			recalibrate_centroid.call_deferred.call_deferred() # Double-deferral will cause this to execute very very last
	for poly in connections: # Pull all bodiless connections into this body
		if is_instance_valid(poly):
			if poly.body == null:
				# Assign connection to own body
				poly.body = body
	# Enter assigned body
	collider.reparent.call_deferred(body)

## Checks if this body has polygons attached to any anchors
func recalibrate_anchors() -> void:
	if body.freeze:
		var anchored = false
		for poly_col in body.get_children():
			var poly = poly_col.get_child(0)
			var global_poly = poly.global_polygon()
			for anchor in poly.anchor_locations:
				if Geometry2D.is_point_in_polygon(anchor, global_poly):
					anchored = true
					break
		body.freeze = anchored

## Fixes the center of gravity for the parent body (only needs to be applied once per body, not per polygon)
func recalibrate_centroid() -> void:
	# Check anchors
	recalibrate_anchors()
	
	# Freeze the body to not interfere with physics
	var original_linear_velocity = body.linear_velocity
	var original_angular_velocity = body.angular_velocity
	var was_frozen = body.freeze
	body.freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	body.freeze = true
	
	# Calculate the centroid (in unrotated world space) by performing an average of all centroids weighted by area, and mass
	var centroid = Vector2.ZERO
	var total_mass = 0
	var poly_count = body.get_children().size()
	for poly_col in body.get_children():
		# The centroid does not account for rotation, as rotation of the body will do all that is needed
		var mass = polygon_area(poly_col.polygon) * poly_col.get_child(0).density # Density determined by each polygon individually, overlaps count
		centroid += polygon_centroid(move_polygon(poly_col.polygon, poly_col.global_position)) * mass
		total_mass += mass
	
	if poly_count * total_mass == 0: # Sure.
		queue_free()
		return
	centroid /= poly_count * ( total_mass / poly_count ) # Finish average
	body.mass = abs(total_mass) / 10000 # Also calculate the mass based on density and total area of each polygon
	
	# Move all polygon origins to the centroid and offset polygons properly
	for poly_col in body.get_children():
		poly_col.polygon = move_polygon(poly_col.polygon, poly_col.global_position - centroid) # Offset polygon
		poly_col.position = Vector2.ZERO # Move origin to centroid
		poly_col.get_child(0).polygon = poly_col.polygon # Set visual polygon
		poly_col.get_child(0).polygon_changed.emit()
	
	# Move the body to the centroid, centroid calibration is now complete
	body.global_position = centroid
	
	# Unfreeze the body so it will resume interaction with physics
	body.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	body.freeze = was_frozen
	body.linear_velocity = original_linear_velocity
	body.angular_velocity = original_angular_velocity


func _notification(what):
	if what == NOTIFICATION_PREDELETE: # Destroy empty bodies
		if is_instance_valid(body):
			if body.get_children().size() == 0:
				body.queue_free()
		else:
			if collider:
				collider.queue_free()
			else:
				queue_free()

func apply_hole(hole_global_poly: PackedVector2Array) -> void:
	## Calibrate rotation to 0
	for poly_col in body.get_children():
		var poly = poly_col.get_child(0)
		poly_col.polygon = rotate_polygon(poly_col.polygon, Vector2.ZERO, body.rotation)
		poly.polygon = poly_col.polygon
	body.rotation = 0
	
	## Clip polygons
	for poly_col in body.get_children():
		var poly = poly_col.get_child(0)
		var clips = Geometry2D.clip_polygons(poly.global_polygon(), hole_global_poly)
		if clips.size() == 0: # Destroy complete clips
			if body.get_children().size() == 1:
				body.queue_free()
			poly_col.queue_free()
		elif polygon_area(clips[0]) != polygon_area(poly.global_polygon()):
			if poly.fragile:
				if body.get_children().size() == 1:
					body.queue_free()
				poly_col.queue_free()
			else:
				var new_poly = poly_col
				for clip in clips: # Create new polygons for splits
					new_poly.polygon = poly.global_to_local_polygon(clip)
					new_poly.get_child(0).polygon = new_poly.polygon
					if polygon_area(new_poly.polygon) != polygon_area(poly_col.polygon):
						body.add_child(new_poly)
					new_poly = poly_col.duplicate()
					new_poly.get_child(0).anchor_locations = poly_col.get_child(0).anchor_locations
	
	if body:
		disconnect_polygons()
		recalibrate_centroid()

func disconnect_polygons() -> void:
	## Get the groups of connected polygons
	var groups = []
	for poly in body.get_children():
		groups.append({poly: true})
	for i in range(body.get_children().size()):
		var poly = body.get_child(i)
		for j in range(body.get_children().size() - i - 1):
			var other_poly = body.get_child(j + i + 1)
			if Geometry2D.intersect_polygons(poly.polygon, other_poly.polygon).size() > 0:
				var found_group = null
				for group in groups:
					if group.has(poly) and not group.has(other_poly):
						group[other_poly] = true
						found_group = group
					elif group.has(other_poly) and not group.has(poly):
						group[poly] = true
						if found_group == null:
							found_group = group
						else:
							found_group.merge(group)
							groups.erase(group)
	
	## Split into new bodies and recalibrate
	for i in range(groups.size()):
		var group = groups[i]
		if i != groups.size() - 1:
			var new_body = RigidBody2D.new()
			new_body.set_meta("IS_POLYBODY", true) # Other scripts will be able to tell this is a PolyBody body with this metadata
			new_body.freeze = true # Will be recalibrated later
			new_body.linear_velocity = body.linear_velocity
			new_body.angular_velocity = body.angular_velocity
			body.get_parent().add_child(new_body)
			for poly_col in group:
				poly_col.reparent(new_body)
				poly_col.get_child(0).body = new_body
		group.keys()[0].get_child(0).recalibrate_centroid()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if draw_info:
		#draw_circle(body.global_position - global_position, 9, Color(info_color, 0.5))
		#draw_circle(collider.global_position - global_position, 6, Color(info_color, 0.5))
		#draw_circle(polygon_centroid(move_polygon(polygon, collider.global_position)) - global_position, 3, Color(info_color, 0.5))
		draw_circle(Vector2.ZERO, 3, Color(info_color, 0.5))


## Get this polygon's points in world space
func global_polygon() -> PackedVector2Array:
	return move_polygon(rotate_polygon(polygon, Vector2.ZERO, body.rotation), global_position)

## Convert from this polygon's points in world space to the local polygon
func global_to_local_polygon(global_poly: PackedVector2Array) -> PackedVector2Array:
	return rotate_polygon(move_polygon(global_poly, -global_position), Vector2.ZERO, -body.rotation)


## HELPER - Offset all points in a polygon
func move_polygon(poly: PackedVector2Array, by: Vector2) -> PackedVector2Array:
	var moved_poly = PackedVector2Array()
	for v in poly:
		moved_poly.append(v + by)
	return moved_poly
## HELPER - Rotate all points in a polygon around a specified point
func rotate_polygon(poly: PackedVector2Array, around: Vector2, by: float) -> PackedVector2Array:
	var rotd_poly = PackedVector2Array()
	for v in poly:
		var rotated_vector = (v - around).rotated(by) + around
		rotd_poly.append(rotated_vector)
	return rotd_poly
## HELPER - Calculate the area of a polygon
func polygon_area(poly: PackedVector2Array) -> float:
	var result := 0.0
	var num_vertices := poly.size()
	
	for q in range(num_vertices):
		var p = (q - 1 + num_vertices) % num_vertices
		result += poly[q].cross(poly[p])
	
	return result * 0.5
## HELPER - Calculate the centroid of a polygon
func polygon_centroid(poly: PackedVector2Array) -> Vector2:
	var centroid = Vector2()
	var area = polygon_area(poly)
	var num_vertices = poly.size()
	var factor = 0.0
	
	for q in range(num_vertices):
		var p = (q - 1 + num_vertices) % num_vertices
		factor = poly[q].cross(poly[p])
		centroid += (poly[q] + poly[p]) * factor
	
	centroid /= (6.0 * area)
	return centroid
