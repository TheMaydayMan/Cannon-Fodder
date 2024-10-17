extends Polygon2D
class_name PolyHole

var collider : CollisionPolygon2D
var area : Area2D
var searching_left = 2 # The area gets three attempts to overlap anything

func _ready() -> void:
	# Ensure rotation to be zero
	polygon = rotate_polygon(polygon, Vector2.ZERO, rotation)
	rotation = 0
	# Create new collider
	collider = CollisionPolygon2D.new()
	collider.polygon = polygon
	collider.global_transform = global_transform
	# Reparent to the collider
	get_parent().add_child.call_deferred(collider)
	reparent.call_deferred(collider)
	# Create and reparent to new area
	area = Area2D.new()
	get_parent().add_child.call_deferred(area)
	collider.reparent.call_deferred(area)
	await get_tree().create_timer(1).timeout
	apply()

func apply() -> void:
	var overlapping_bodies = area.get_overlapping_bodies()
	if overlapping_bodies.size() == 0:
		if searching_left > 0: # The area gets three attempts to overlap anything
			searching_left -= 1
			await get_tree().physics_frame
			apply()
			return
	else:
		for body in overlapping_bodies:
			if body.get_meta("IS_POLYBODY"):
				body.get_child(0).get_child(0).apply_hole(global_polygon())
	area.queue_free() # Destroy the area once application is finished (or if collision fails)

## Get this polygon's points in world space
func global_polygon() -> PackedVector2Array:
	return move_polygon(rotate_polygon(polygon, Vector2.ZERO, area.rotation), global_position)

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
