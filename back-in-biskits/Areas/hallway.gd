extends Node2D

# Hallways are rest areas between boss fights.
func _ready() -> void:
	Global.potency_paused = true
	var ui_node = get_tree().get_first_node_in_group("ui")
	if ui_node and ui_node.has_method("stop_stopwatch"):
		ui_node.stop_stopwatch()
