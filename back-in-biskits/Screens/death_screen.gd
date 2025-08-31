extends Control

@onready var menu = $Menu
@onready var retry = $Retry

func _ready():
	match Global.stage:
		1:
			$Label.text = "Captain, Captain? I thought we're just playing.. oh well"
			$Sprite2D.texture = preload("res://Assets/Bosses/Cat Boss/Cat_Win.png")
		2:
			$Label.text = "Crumbled and Cooked, such low caliber..."
			$Sprite2D.texture = preload("res://Assets/Bosses/Candy Boss/candy-win.png")
		3:
			$Label.text = "Cookie?- Was i too powerful little hero?"
			$Sprite2D.texture = preload("res://Assets/Bosses/Cookie Mosnter Boss/confectioneer-win.png")
		_:
			pass

func _on_menu_pressed():
	get_tree().change_scene_to_file("res://Screens/title_screen.tscn")

func _on_retry_pressed():
	Global.potency = 1
	Global.timer = 0
	match Global.stage:
		1:
			get_tree().change_scene_to_file("res://Areas/area_1.tscn")
		2:
			get_tree().change_scene_to_file("res://Areas/area_2.tscn")
		3:
			get_tree().change_scene_to_file("res://Areas/area_3.tscn")
		_:
			get_tree().change_scene_to_file("res://Areas/tutorial.tscn")
