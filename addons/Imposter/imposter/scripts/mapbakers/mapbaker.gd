@tool
extends RefCounted
class_name MapBaker

func get_name() -> String:
	return "unknown"


func is_dilatated() -> bool:
	return false


func use_as_dilatate_mask() -> bool:
	return false


func image_format() -> int:
	return Image.FORMAT_RGBA8



func viewport_setup(viewport: Viewport) -> void:
	pass


func viewport_cleanup(viewport: Viewport) -> void:
	pass



func setup_postprocess_plane(plane: Mesh, camera: Camera3D) -> bool:
	return false

func map_bake(org_material: Material) -> Material:
	return org_material
