@tool
extends Control

@onready var bake_dialog = $BakeFileDialog
@onready var bake_dir_line = $HSplitContainer/Selects/GridContainer/SelectDir/LineEdit
@onready var save_dialog = $SaveFileDialog
@onready var save_dir_line = $HSplitContainer/Selects/GridContainer/SaveDir/LineEdit
@onready var viewport = $HSplitContainer/PreviewNode/ScrollContainer/BoxContainer/SubViewportContainer/SubViewport
@onready var progressbar = $HSplitContainer/PreviewNode/HBoxContainer/ProgressBar
@onready var warin_dialog = $AcceptDialog
@onready var Studio = preload("res://addons/Imposter/imposter/scenes/photostudio.tscn")
var save_dir:String=""
var bake_dir:String=""

#var plugin:EditorPlugin
var photo_sdudio:PhotoStudio 

var is_full_sphere:bool=false
var create_shadow:bool=false
var resolution:int=1024
var frame_size:int=16
var dilatate_distance:int=32
var temp_bar:int

# Called when the node enters the scene tree for the first time.
func _ready():
	#plugin = EditorPlugin.new()
	photo_sdudio = Studio.instantiate()
	viewport.add_child(photo_sdudio)
#	var world3d=World3D.new()
#	var env = Environment.new()
#	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
#	env.ambient_light_color=Color.WHITE
#	env.ssil_enabled=true
#	world3d.environment=env
#	viewport.world_3d=world3d
	viewport.transparent_bg=true
	
	
	init_photo_studio()

func init_photo_studio():
	photo_sdudio.is_full_sphere=is_full_sphere
	photo_sdudio.create_shadow=create_shadow
	photo_sdudio.resolution=resolution
	photo_sdudio.frame_size=frame_size
	photo_sdudio.view_port=viewport
	#photo_sdudio.plugin=plugin
	photo_sdudio.plugin = EditorPlugin.new()
	photo_sdudio.set_dilatate_distance(dilatate_distance)
	photo_sdudio.connect('change_bar',Callable(self,'change_bar_value'))
	

func change_bar_value(bar:int):
	temp_bar+=bar
	progressbar.value=temp_bar
	await progressbar.changed




func _on_bake_file_dialog_dir_selected(dir):
	bake_dir=dir
	bake_dir_line.text = dir
	


func _on_save_file_dialog_dir_selected(dir):
	photo_sdudio.save_dir=dir
	save_dir=dir
	save_dir_line.text = dir


func _on_select_but_pressed():
	bake_dialog.popup_centered()


func _on_save_but_pressed():
	save_dialog.popup_centered()


func _on_generate_pressed():
	if bake_dir=="":
		warin_dialog.dialog_text = 'bake dir is null'
		warin_dialog.popup_centered()
		return
	if save_dir=="":
		warin_dialog.dialog_text = 'save dir is null'
		warin_dialog.popup_centered()
		return
		

	var nodes = get_all_bake_nodes(bake_dir)
	temp_bar=0
	var max_bar = photo_sdudio.get_max_bar_value()*nodes.size()
	progressbar.max_value=max_bar
	progressbar.value=temp_bar
	print(nodes.size())
	for n in nodes:
		if n is Node3D:
			photo_sdudio.set_scene(n)
			photo_sdudio.base_filename=n.name
			photo_sdudio.bake()
			await photo_sdudio.bake_finished
		n.queue_free()
	print('End of baking!')
	
func get_all_bake_nodes(path:String)->Array:
	var nodes=[]
	var dir = DirAccess.open(path)
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file=="":
			break
			
		if dir.current_is_dir():
			nodes+=get_all_bake_nodes("%s/%s"%[path,file])
		elif file.ends_with('tscn'):
			var filename = '%s/%s'%[path,file]
			var nodename = file.get_basename().split('/')[-1]
			var node = load(filename).instantiate()
			node.name = nodename
			nodes.append(node)
		
	return nodes

func _on_full_sphere_but_toggled(button_pressed):
	is_full_sphere=button_pressed
	photo_sdudio.is_full_sphere=button_pressed


func _on_shadow_but_toggled(button_pressed):
	create_shadow=button_pressed
	photo_sdudio.create_shadow=button_pressed




func _on_frame_but_value_changed(value):
	frame_size=int(value)
	photo_sdudio.frame_size=frame_size



func _on_dilatate_spin_value_changed(value):
	dilatate_distance=int(value)
	photo_sdudio.set_dilatate_distance(dilatate_distance)


func _on_resolution_but_value_changed(value):
	resolution=int(value)
	photo_sdudio.resolution=resolution
