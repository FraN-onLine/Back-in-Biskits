extends Control

@onready var main_buttons = $VBoxContainer
@onready var start_button = $VBoxContainer/StartButton
@onready var instructions_button = $VBoxContainer/InstructionsButton
@onready var best_times_button = $VBoxContainer/BestTimesButton
@onready var almanac_button = $VBoxContainer/AlmanacButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var quit_button = $VBoxContainer/QuitButton
@onready var options = $SettingsPanel
@onready var best_times_panel = $BestTimesPanel
@onready var almanac_panel = $AlmanacPanel
@onready var button_sound = $buttonsounds

func _ready():
	# Connect button signals
	start_button.pressed.connect(_on_start_pressed)
	instructions_button.pressed.connect(_on_instructions_pressed)
	best_times_button.pressed.connect(_on_best_times_pressed)
	almanac_button.pressed.connect(_on_almanac_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# hide panels at start
	main_buttons.visible = true
	options.visible = false
	best_times_panel.visible = false
	almanac_panel.visible = false
	almanac_panel.back_pressed.connect(_on_back_almanac_pressed)

func _on_start_pressed():
	button_sound.play()
	Global.potency = 1
	Global.timer = 0
	FadeManager.fade_out_then_change_scene("res://Areas/hallway_1.tscn")

func _on_instructions_pressed():
	button_sound.play()
	show_instructions()

func _on_settings_pressed():
	button_sound.play()
	print("Settings Pressed")
	main_buttons.visible = false
	options.visible = true
	#show_settings() 

func _on_quit_pressed():
	button_sound.play()
	get_tree().quit()

func _on_best_times_pressed():
	button_sound.play()
	_refresh_best_times()
	main_buttons.visible = false
	best_times_panel.visible = true

func _on_almanac_pressed():
	button_sound.play()
	main_buttons.visible = false
	almanac_panel.visible = true
	almanac_panel.open()

func _on_back_almanac_pressed():
	button_sound.play()
	almanac_panel.visible = false
	main_buttons.visible = true

func _on_back_best_times_pressed():
	button_sound.play()
	best_times_panel.visible = false
	main_buttons.visible = true

func _refresh_best_times():
	var names := {1: "BOTANIC PANIC", 2: "CANDY CONNOSIEUR", 3: "CONFECTIONEER"}
	var rows := PackedStringArray()
	for stage in [1, 2, 3]:
		var best := Global.get_best_time(stage)
		var time_text := Global.format_time(best) if best > 0.0 else "--:--"
		rows.append("%d. %s   %s" % [stage, names[stage], time_text])
	best_times_panel.get_node("BestTimesLabel").text = "\n".join(rows)

func show_instructions():
	var dialog = AcceptDialog.new()
	dialog.title = "Instructions"
	dialog.dialog_text = "Lion Cracker - a melee ranged weapon
						Graham - a long ranged projectile weapon
						Macaroon - a mid ranged omni directional weapon
						Cookie Cat - a shield that can block 1 point of damage
						Pistachio - a melee ranged AoE weapon
						Oreo - a movement type weapon that let's you dash through enemies"
	add_child(dialog)
	dialog.popup_centered()

#func show_settings():

func _on_back_options_pressed():
	button_sound.play()
	options.visible = false
	main_buttons.visible = true
