extends CanvasLayer

# Pause menu - toggled with ESC during gameplay.
# While open the whole SceneTree is paused, which stops movement, attacks,
# potency gain, timers and the stopwatch. This node runs in PROCESS_MODE_ALWAYS
# so it still works (and its buttons remain clickable) while the tree is paused.

@onready var menu_panel: Control = $MenuPanel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	menu_panel.visible = false
	$MenuPanel/Panel/VBox/ContinueButton.pressed.connect(_on_continue_pressed)
	$MenuPanel/Panel/VBox/MainMenuButton.pressed.connect(_on_main_menu_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if get_tree().paused:
			_resume()
		else:
			_pause()
		get_viewport().set_input_as_handled()


func _pause() -> void:
	menu_panel.visible = true
	get_tree().paused = true


func _resume() -> void:
	menu_panel.visible = false
	get_tree().paused = false


func _on_continue_pressed() -> void:
	_resume()


func _on_main_menu_pressed() -> void:
	# Keep the game paused while the fade runs so the player can't move;
	# FadeManager unpauses the tree when the title screen loads.
	menu_panel.visible = false
	Global.dialog_open = false
	Global.warning_enabled = false
	FadeManager.fade_out_then_change_scene("res://Screens/title_screen.tscn")