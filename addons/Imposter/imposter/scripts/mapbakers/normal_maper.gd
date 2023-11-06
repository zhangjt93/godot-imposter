@tool

# extends OctahedralImpostorMapBaker
extends MapBaker

var normal_material = preload("res://addons/Imposter/imposter/materials/normal_baker.material")

func get_name() -> String:
	return "normal"


func is_dilatated() -> bool:
	return true


func image_format() -> int:
	return Image.FORMAT_RGH



func _cleanup_baking_material(material: ShaderMaterial) -> void:
	material.set_shader_parameter("texture_albedo", null)
	material.set_shader_parameter("normal_texture", null)
	material.set_shader_parameter("alpha_scissor_threshold", 0.0)
	material.set_shader_parameter("normal_scale", 0.0)
	material.set_shader_parameter("use_normalmap", false)
	material.set_shader_parameter("use_alpha_texture", false)


func _mimic_original_spatial_material(original_mat: BaseMaterial3D, material: ShaderMaterial) -> void:
	if original_mat.normal_enabled:
		material.set_shader_parameter("normal_texture", original_mat.normal_texture)
		material.set_shader_parameter("use_normalmap", true)
		material.set_shader_parameter("normal_scale", original_mat.normal_scale)
#	if original_mat.params_use_alpha_scissor:
	if original_mat.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR:
		material.set_shader_parameter("use_alpha_texture", true)
		material.set_shader_parameter("alpha_scissor_threshold", original_mat.alpha_scissor_threshold)
		material.set_shader_parameter("texture_albedo", original_mat.albedo_texture)


func _mimic_original_shader_material(original_mat: ShaderMaterial, material: ShaderMaterial) -> void:
	# TODO ADD NORMAL TEXTURE, ORM
	var alpha_scissors = original_mat.get_shader_parameter("alpha_scissor_threshold")
	var albedo_tex = original_mat.get_shader_parameter("texture_albedo")
	if alpha_scissors != null and float(alpha_scissors) > 0.0 and albedo_tex != null:
		material.set_shader_parameter("use_alpha_texture", true)
		material.set_shader_parameter("texture_albedo", albedo_tex)
		material.set_shader_parameter("alpha_scissor_threshold", alpha_scissors)
	else:
		print("Alpha texture not recognized")


func map_bake(org_material: Material) -> Material:
	_cleanup_baking_material(normal_material)
	var mat_baking = normal_material.duplicate()
	if org_material is BaseMaterial3D:
		_mimic_original_spatial_material(org_material, mat_baking)
	elif org_material is ShaderMaterial:
		_mimic_original_shader_material(org_material, mat_baking)
	else:
		print("Unrecognized material during normal baking")
	return mat_baking
