extends Control

@onready var menu = $Menu
@onready var retry = $Retry

func _ready():
	menu.pressed.connect(_on_menu_pressed)
	retry.pressed.connect(_on_retry_pressed)

func _on_menu_pressed():
	get_tree().change_scene_to_file("res://Screens/title_screen.tscn")

func _on_retry_pressed():
	get_tree().change_scene_to_file("res://Areas/area_1.tscn")
