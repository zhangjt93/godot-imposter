@tool
extends PanelContainer
@onready var Single = preload("res://addons/Imposter/imposter/scenes/single_bake.tscn")
@onready var Batch = preload("res://addons/Imposter/imposter/scenes/batch_bake.tscn")
@onready var subs:TabContainer = $TabContainer

func _ready():
	subs.use_hidden_tabs_for_min_size=true
	subs.drag_to_rearrange_enabled=true
	var view_size: Vector2i = EditorInterface.get_editor_viewport_2d().size
	subs.custom_minimum_size = view_size - (Vector2i(view_size*0.1))
	var single_bake = Single.instantiate()
	subs.add_child(single_bake)
	var batch_bake = Batch.instantiate()
	subs.add_child(batch_bake)
