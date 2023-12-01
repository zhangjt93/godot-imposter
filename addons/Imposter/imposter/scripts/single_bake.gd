@tool
extends Control

@onready var file_dialog = $FileDialog
@onready var warin_dialog = $AcceptDialog
@onready var save_path_edit = $HSplitContainer/Selects/GridContainer/SaveDir/LineEdit
@onready var progressbar = $HSplitContainer/PreviewNodes/HBoxContainer/ProgressBar
@onready var filename = $HSplitContainer/Selects/GridContainer/FileName/LineEdit
@onready var viewport = $HSplitContainer/PreviewNodes/Preview/BoxContainer/PreviewScenes/Viewport
@onready var Studio = preload("res://addons/Imposter/imposter/scenes/photostudio.tscn")

#region godot 4.2+ ,variables can be deleted
var plugin:EditorPlugin
var interface:EditorInterface
#endregion

var photo_sdudio:PhotoStudio 

var save_path:String
var is_full_sphere:bool=false
var create_shadow:bool=false
var resolution:int=1024
var frame_size:int=16
var dilatate_distance:int=32


var temp_bar:int

# Called when the node enters the scene tree for the first time.
func _ready():
	
#region godot 4.2+ ,variables can be deleted
	plugin = EditorPlugin.new()
	interface = plugin.get_editor_interface()
#endregion
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
	photo_sdudio.base_filename=filename.text
#region godot 4.2+ use the following line of code,Delete variable plugin and interface
	photo_sdudio.plugin=plugin
	#photo_sdudio.plugin=EditorPlugin.new()
#endregion
	photo_sdudio.set_dilatate_distance(dilatate_distance)
	photo_sdudio.connect('change_bar',Callable(self,'change_bar_value'))
	

func change_bar_value(bar:int):
	temp_bar+=bar
	progressbar.value=temp_bar
	await progressbar.changed


func _on_generate_pressed():
	temp_bar=0
	var max_bar = photo_sdudio.get_max_bar_value()
	progressbar.max_value=max_bar
	progressbar.value=temp_bar
	photo_sdudio.bake()


func _on_process_pressed():

#region godot 4.2+ use the following line of code
	var sels = interface.get_selection().get_selected_nodes()
	#var sels = EditorInterface.get_selection().get_selected_nodes()
#endregion

	if sels.size()!=1:
		warin_dialog.dialog_text = 'select one node'
		warin_dialog.popup_centered()
		return
	
	var sel = sels[0]
	if not sel is Node3D:
		warin_dialog.dialog_text = 'select 3d node'
		warin_dialog.popup_centered()
		return
	
	photo_sdudio.set_scene(sel)
	filename.text = sel.name
	photo_sdudio.base_filename=sel.name
		
	

func _on_save_but_pressed():
	file_dialog.popup_centered()



func _on_full_sphere_but_toggled(button_pressed):
	is_full_sphere=button_pressed
	photo_sdudio.is_full_sphere=button_pressed
	photo_sdudio.prepare_scene()
	

func _on_shadow_but_toggled(button_pressed):
	create_shadow=button_pressed
	photo_sdudio.create_shadow=button_pressed





func _on_file_dialog_dir_selected(dir):
	photo_sdudio.save_dir=dir
	save_path=dir
	save_path_edit.text = dir




func _on_line_edit_text_submitted(new_text):
	photo_sdudio.base_filename=new_text
	


func _on_line_edit_text_changed(new_text):
	photo_sdudio.base_filename=new_text


func _on_frame_spin_value_changed(value):
	frame_size=int(value)
	photo_sdudio.frame_size=frame_size
	photo_sdudio.prepare_scene()


func _on_resolution_spin_value_changed(value):
	resolution=int(value)
	photo_sdudio.resolution=resolution
#	photo_sdudio.init_bake_scene()
	photo_sdudio.prepare_scene()


func _on_spin_box_value_changed(value):
	dilatate_distance=int(value)
	photo_sdudio.set_dilatate_distance(dilatate_distance)
