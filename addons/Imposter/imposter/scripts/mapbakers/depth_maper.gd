@tool

# extends OctahedralImpostorMapBaker
extends MapBaker

var depth_material = preload("res://addons/Imposter/imposter/materials/depth_baker.material")

func get_name() -> String:
	return "depth"


func is_dilatated() -> bool:
	return true


func setup_postprocess_plane(plane: Mesh, camera: Camera3D) -> bool:
	depth_material.set_shader_parameter("depth_scaler", camera.far )
	plane.surface_set_material(0,depth_material)
	return true


func image_format() -> int:
	return Image.FORMAT_R8
