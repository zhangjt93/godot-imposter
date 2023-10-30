class_name OctaUtils

# |x|+|y|+|z|=1
static func hemisphere_octa(coord: Vector2) -> Vector3:
	var position: Vector3 = Vector3(coord.x - coord.y, 0, -1.0 + coord.x + coord.y)
	var absolute: Vector3 = position.abs()
	position.y = 1.0 - absolute.x - absolute.z

	return position

static func sphere_octa(coord: Vector2) -> Vector3:
	coord = coord * 2.0 - Vector2(1.0, 1.0)
	var position: Vector3 = Vector3(coord.x, 0, coord.y)
	var absolute: Vector3 = position.abs()
	position.y = 1.0 - absolute.x - absolute.z

	if position.y < 0:
		var pos_sign: Vector3 = position.sign()
		position.x = pos_sign.x * (1.0 - absolute.z)
		position.z = pos_sign.z * (1.0 - absolute.x)

	return position

static func octa_uv_to_world(coord: Vector2, is_full_sphere: bool) -> Vector3:
	if is_full_sphere:
		return sphere_octa(coord).normalized()
	else:
		return hemisphere_octa(coord).normalized()
