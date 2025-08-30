extends Control

@onready var main_buttons = $VBoxContainer
@onready var start_button = $VBoxContainer/StartButton
@onready var instructions_button = $VBoxContainer/InstructionsButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var quit_button = $VBoxContainer/QuitButton
@onready var options = $SettingsPanel

func _ready():
	# Connect button signals
	start_button.pressed.connect(_on_start_pressed)
	instructions_button.pressed.connect(_on_instructions_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# hide settings panel at start
	main_buttons.visible = true
	options.visible = false

func _on_start_pressed():
	Global.potency = 1
	Global.timer = 0
	FadeManager.fade_out_then_change_scene("res://Areas/tutorial.tscn")

func _on_instructions_pressed():
	show_instructions()

func _on_settings_pressed():
	print("Settings Pressed")
	main_buttons.visible = false
	options.visible = true
	#show_settings() 

func _on_quit_pressed():
	get_tree().quit()

func show_instructions():
	var dialog = AcceptDialog.new()
	dialog.title = "Instructions"
	dialog.dialog_text = "Wait lang children"
	add_child(dialog)
	dialog.popup_centered()

#func show_settings():

func _on_back_options_pressed():
	_ready()
