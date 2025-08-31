extends Node2D

func _ready() -> void:
	Global.stage = 1
	var ui_node = get_tree().get_first_node_in_group("ui")
	if ui_node and ui_node.has_method("start_stopwatch"):
		ui_node.start_stopwatch()
