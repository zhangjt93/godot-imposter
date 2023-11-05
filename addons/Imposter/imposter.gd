@tool
extends PanelContainer
@onready var Single = preload("res://addons/Imposter/imposter/scenes/single_bake.tscn")
@onready var Batch = preload("res://addons/Imposter/imposter/scenes/batch_bake.tscn")
@onready var subs:TabContainer = $TabContainer
func _ready():
	subs.use_hidden_tabs_for_min_size=true
	subs.drag_to_rearrange_enabled=true
	subs.custom_minimum_size=Vector2i(2048,600)
	subs.set_anchors_preset(Control.PRESET_FULL_RECT)
	var single_bake = Single.instantiate()
	subs.add_child(single_bake)
	var batch_bake = Batch.instantiate()
	subs.add_child(batch_bake)

	
