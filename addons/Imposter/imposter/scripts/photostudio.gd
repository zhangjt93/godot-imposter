@tool
extends Node3D
class_name PhotoStudio
@onready var arena = $Arena

@onready var bake_camera = $Camera3D
@onready var masking = $Camera3D/MeshInstance3D
@onready var maps = [preload("res://addons/Imposter/imposter/scripts/mapbakers/albedo_maper.gd").new(),
						preload("res://addons/Imposter/imposter/scripts/mapbakers/normal_maper.gd").new(),
						preload("res://addons/Imposter/imposter/scripts/mapbakers/depth_maper.gd").new(),
						preload("res://addons/Imposter/imposter/scripts/mapbakers/orm_maper.gd").new()]
@onready var dialog:AcceptDialog = $AcceptDialog
@onready var dilatate = $Dilatate
@onready var bake_plan = $Camera3D/MeshInstance3D

const shadow_filename_prefix = "shadow"
const base_filename_prefix="base"
const base_shader = "res://addons/Imposter/imposter/materials/shaders/ImpostorShader.gdshader"
const shadow_shader = "res://addons/Imposter/imposter/materials/shaders/ImpostorShaderShadows.gdshader"

signal saved
signal bake_finished
signal change_bar(bar:int)

var is_full_sphere:bool=false
var frame_size:int=4
var create_shadow:bool=false
var camera_distance:float
var camera_distance_scaled:float
var resolution:int=1024
var save_dir:String
var base_filename:String
var view_port:SubViewport = null

var bake_scene:Node3D=null
var width:int
var material_cache = {}
var saved_maps={}
#region godot 4.2+ this variable can be deleted
var plugin:EditorPlugin
#endregion


func get_max_bar_value()->int:
	return 2*maps.size()+1

func bake():
	if bake_scene==null:
		dialog.dialog_text='Check your node,bake node is null'
		dialog.popup_centered()
		return
	
	
	material_cache={}
	saved_maps={}

	width = resolution/frame_size
	cache_materials(bake_scene)

	for m in maps:
		bake_texture(m)
		await self.saved
	

	var shader_mat := ShaderMaterial.new()
	shader_mat.shader = preload(base_shader)
	var shader_shadow_mat: ShaderMaterial = null
	if create_shadow:
		shader_shadow_mat = ShaderMaterial.new()
		shader_shadow_mat.shader = preload(shadow_shader)
		
	await export_scene(shader_mat, false, shader_shadow_mat)
		
	recover_materials(bake_scene)
	dilatate.clean()
	init_bake_scene()
	bake_finished.emit()

	
	
func bake_texture(maper:MapBaker):
	maper.viewport_setup(view_port)
	map_baker_process_materials(maper,bake_scene)
	prepare_scene()
	await RenderingServer.frame_post_draw 
	
	if maper.setup_postprocess_plane(masking.mesh,bake_camera):
		masking.visible = true
		
	var img = view_port.get_texture().get_image()
	img.convert(maper.image_format())
	change_bar.emit(1)
	postprocess_plane_cleanup()

	if maper.is_dilatated():
		var r = await dilatate.dilatate(img,maper.use_as_dilatate_mask())
		img = dilatate.processed_image
		img.convert(maper.image_format())
	
	export_texture(maper,img,base_filename_prefix)
	change_bar.emit(1)
	

func cache_materials(scene:Node3D):
	if scene is MeshInstance3D:
		var arr = []
		
		var mats: int = scene.get_surface_override_material_count()
		arr.resize(mats)
		for m in mats:
			var original_mat = scene.get_surface_override_material(m)
			if original_mat==null:
				original_mat=scene.mesh.surface_get_material(m)
			arr[m]=original_mat
		material_cache[scene.get_instance_id()]=arr
		
	for child in scene.get_children():
		cache_materials(child)

func recover_materials(scene:Node3D):
	if scene is MeshInstance3D:
		var mats: int = scene.get_surface_override_material_count()
		for m in mats:
			scene.set_surface_override_material(m,material_cache[scene.get_instance_id()][m])
	for child in scene.get_children():
		recover_materials(child)

func map_baker_process_materials(maper: MapBaker, scene: Node3D) -> void:
	if scene is MeshInstance3D:
		
		var mats: int = scene.get_surface_override_material_count()
		for m in mats:
			var original_mat=material_cache[scene.get_instance_id()][m]
			var map_to_bake_mat = maper.map_bake(original_mat)
			scene.set_surface_override_material(m, map_to_bake_mat)
			
	for child in scene.get_children():
		map_baker_process_materials(maper, child)



func get_camera_coord(index:int)->Vector2i:
	return Vector2i(index/frame_size,index%frame_size)
	

func init_bake_scene():
	if bake_scene==null:
		dialog.dialog_text='Check your node，init scene node is null'
		dialog.popup_centered()
		return
		
	for c in arena.get_children():
		arena.remove_child(c)
		c.queue_free()


	arena.add_child(bake_scene)
	bake_scene.show()

	bake_scene.position=Vector3.ZERO
	var max_aabb = get_max_aabb(bake_scene)
	camera_distance = max_aabb.size.length()
	#if aabb size < 0.0001 
	if camera_distance<=0.0001:
		dialog.dialog_text='Check your node,aabb size Approximate to 0'
		dialog.popup_centered()
		return

	bake_scene.position -= max_aabb.get_center()
	
	camera_distance_scaled = camera_distance / float(frame_size)
	bake_camera.size = camera_distance
	bake_camera.near = camera_distance_scaled/10.0
	bake_camera.far = camera_distance_scaled * 2.0
	bake_camera.global_transform.origin.z = camera_distance_scaled

	bake_camera.look_at(Vector3.ZERO)
	arena.remove_child(bake_scene)
	
	
func prepare_scene():
	view_port.size=Vector2i(resolution,resolution)

	
	init_bake_scene()
	
	for x in frame_size:
		for y in frame_size:
			var normal := OctaUtils.octa_uv_to_world(Vector2(float(x)/(frame_size-1),float(y)/(frame_size-1)), is_full_sphere)
			
			var cam_pos = Marker3D.new()
			var container := Node3D.new()
			var d_baked_scene = bake_scene.duplicate()
			
			d_baked_scene.rotation = Vector3()
			container.add_child(d_baked_scene)
			container.add_child(cam_pos)
			arena.add_child(container)
			container.show()
			d_baked_scene.show()
			cam_pos.show()
			
			var pos = normal * camera_distance
			
			if normal.abs() == Vector3(0, 1, 0):
				cam_pos.look_at_from_position(pos, Vector3.ZERO, Vector3.BACK)
			else:
				cam_pos.look_at_from_position(pos, Vector3.ZERO, Vector3.UP)

			d_baked_scene.transform = cam_pos.transform.affine_inverse() * d_baked_scene.transform

			d_baked_scene.global_transform.origin.z = 0

			var scale := camera_distance / float(frame_size)
			container.scale*=1/float(frame_size)
			container.transform.origin=Vector3.ZERO
			container.position.x = (float(frame_size)/2.0 - float(x)-0.5 )* (-scale)
			container.position.y = (float(frame_size)/2.0 - float(y)-0.5 )* scale
#
			container.remove_child(cam_pos)
			cam_pos.queue_free()

		
	await RenderingServer.frame_post_draw 
	await get_tree().process_frame
	await get_tree().process_frame
	
	
func set_scene(node:Node3D):

	if view_port==null:
		return
		
	init_studio()
	view_port.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	bake_scene = node.duplicate()
	check_mats(bake_scene)
	prepare_scene()

	
func check_mats(node:Node3D):
	if node is MeshInstance3D:
		var mats: int = node.get_surface_override_material_count()
		for m in mats:
			var original_mat = node.get_surface_override_material(m)
			if original_mat==null:
				original_mat=node.mesh.surface_get_material(m)
				
			if original_mat!=null and original_mat.subsurf_scatter_enabled:
				var bake_mat:BaseMaterial3D = original_mat.duplicate(true)
				bake_mat.subsurf_scatter_enabled=false
				node.set_surface_override_material(m,bake_mat)
			
	for c in node.get_children():
		check_mats(c)
	
	
func export_texture(maper:MapBaker,image:Image,prefix:String):
	if save_dir=="" or save_dir == null:
		dialog.dialog_text='Check your directory and file name'
		dialog.popup_centered()
		return

	var filename ="%s/%s_%s_%s.png"%[save_dir,prefix,base_filename,maper.get_name()]
	
	if FileAccess.file_exists(filename):
		DirAccess.remove_absolute(filename)
	var result = image.save_png(filename)
	if result!=OK:
		dialog.dialog_text='Check your directory and file name'
		dialog.popup_centered()
	saved_maps[maper.get_name()]=filename
	change_bar.emit(1)
	saved.emit()
	
		
	
		
	
func export_scene(mat: ShaderMaterial, texture_array: bool = false, shadow_mat: ShaderMaterial = null) -> Node3D:

	if plugin == null:
		print("Cannot export outside plugin system")
		return null

	var root: Node3D = Node3D.new()
	var mi: MeshInstance3D = MeshInstance3D.new()
	var mi_shadow: MeshInstance3D = MeshInstance3D.new()
	var scale_instance = bake_camera.size / 2.0
	var position_offset = bake_scene.position*(-1.0)
	await wait_on_resources()
	print("Creating material...")
	mat.set_shader_parameter("imposterFrames", Vector2(frame_size, frame_size))
	mat.set_shader_parameter("isFullSphere", is_full_sphere)
	mat.set_shader_parameter("aabb_max", scale_instance/2.0)
	mat.set_shader_parameter("scale", scale_instance)
	mat.set_shader_parameter("positionOffset", position_offset)
	
	if shadow_mat != null:
		print("Creating shadow material...")
		shadow_mat.set_shader_parameter("imposterFrames", Vector2(frame_size, frame_size))
		shadow_mat.set_shader_parameter("isFullSphere", is_full_sphere)
		shadow_mat.set_shader_parameter("aabb_max", -scale_instance/2.0)
		shadow_mat.set_shader_parameter("scale", scale_instance)
		shadow_mat.set_shader_parameter("positionOffset", position_offset)
		mi_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY

	print("Loading resources...")
	for x in saved_maps.keys():
		var texture = load(saved_maps[x])
		mat.set_shader_parameter("imposterTexture" + x.capitalize(), texture)
		if shadow_mat != null:
			shadow_mat.set_shader_parameter("imposterTexture" + x.capitalize(), texture)

	var quad_mesh: QuadMesh = QuadMesh.new()
	# Set AABB to occlude properly
	var aabb:AABB = get_max_aabb(bake_scene)
	aabb.size *= 1.5
	quad_mesh.custom_aabb = aabb
	
	root.add_child(mi)
	root.name = "Impostor"
	mi.owner = root
	mi.name = "mesh-impostor"
	mi.mesh = quad_mesh
	mi.mesh.surface_set_material(0, mat)
	if shadow_mat != null:
		root.add_child(mi_shadow)
		mi_shadow.owner = root
		mi_shadow.mesh = quad_mesh.duplicate()
		mi_shadow.name = "shadow-impostor"
		mi_shadow.mesh.surface_set_material(0, shadow_mat)

	var packed_scene: PackedScene = PackedScene.new()
	
	packed_scene.pack(root)
	var impostername = "%s/%s_imposter.tscn"%[save_dir,base_filename]
	var err = ResourceSaver.save(packed_scene,impostername)
	if err != OK:
		print("Error while exporting to path: ", impostername)
		print("Failure! CODE =", err)
		return null
	else:
		print("Imposter ready!")
	change_bar.emit(1)
	return root


func all_resource_exists() -> bool:
	for x in saved_maps:
		if not ResourceLoader.exists(saved_maps[x]):
			return false
	return true


func wait_on_resources() -> void:
	await rescan_filesystem()
	print("Waiting for import to finish...")
	for counter in saved_maps.size() * 2.0:
		await get_tree().process_frame
	
	print("Waiting for resources on disk...")
	while not all_resource_exists():
		await get_tree().process_frame
		await get_tree().process_frame
	
	print("Resource should now exists...")
	for counter in saved_maps.size() * 2.0:
		await get_tree().process_frame
	
	print("Waiting for correct texture loading")
	for x in saved_maps:
		wait_for_correct_load_texture(saved_maps[x])
		
#
func wait_for_correct_load_texture(path: String) -> void:
	var texture = null
	while texture == null:
		texture = load(path)
		await get_tree().process_frame
#
func rescan_filesystem():
#region godot 4.2+ use the following line of code
	var plugin_filesystem = plugin.get_editor_interface().get_resource_filesystem()
	#var plugin_filesystem = EditorInterface.get_resource_filesystem()
#endregion

	plugin_filesystem.scan()
	print("Scanning filesystem...")
	await get_tree().process_frame
	while plugin_filesystem.is_scanning():
		await get_tree().process_frame
		if not is_inside_tree():
			print("Not inside a tree...")
			return


func init_studio():
	
	if bake_scene!=null:
		bake_scene.queue_free()
	bake_scene=null
	
func get_max_aabb(node:Node3D) -> AABB:
	var aabbs = get_all_aabb(node)
	if aabbs.size()==0:
		return AABB()
	else:
		var aabb:AABB = aabbs[0]
		for i in range(1,aabbs.size()):
			aabb = aabb.merge(aabbs[i])
		return aabb

func get_all_aabb(node:Node3D)->Array:
	var result = []
	if node is GeometryInstance3D and not node is CSGShape3D:
		var child_aabb = get_and_rotat_aabb(node)
		result.append(child_aabb)
		
	
	for child in node.get_children():
		result+= get_all_aabb(child)

	return result

func get_and_rotat_aabb(node:Node3D)->AABB:
	var aabb:AABB = node.get_aabb()
	return aabb*node.transform.inverse()

func get_scene_max_aabb(node:Node3D) -> AABB:
	var aabbs = get_scene_all_aabb(node,node.global_position)
	if aabbs.size()==0:
		return AABB()
	else:
		var aabb:AABB = aabbs[0]
		for i in range(1,aabbs.size()):
			aabb = aabb.merge(aabbs[i])
		return aabb
	
func get_scene_all_aabb(node:Node3D,base_point:Vector3)->Array:
	var result = []
	if node is GeometryInstance3D and not node is CSGShape3D:
		var child_aabb = get_and_rotat_aabb(node)
		child_aabb.position += (node.global_position-base_point)-Vector3.ZERO
		result.append(child_aabb)
		
	
	for child in node.get_children():
		result+= get_scene_all_aabb(child,base_point)

	return result
	
func postprocess_plane_cleanup() -> void:
	masking.visible = false
	masking.mesh.surface_set_material(0, null)
	
func set_dilatate_distance(value)->void:
	dilatate.set_dilatate_distance(value)
