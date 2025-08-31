extends Control

@onready var menu = $Menu
@onready var retry = $Retry

func _ready():
	match Global.stage:
		1:
			$Label.text = "Hiss! Hiss! Me-e-e-e-ow!!"
			$Sprite2D.texture = preload("res://Assets/Bosses/Cat Boss/Cat_Win.png")
		2:
			$Label.text = "I won't sugarcoat it...you never stood a chance!"
			$Sprite2D.texture = preload("res://Assets/Bosses/Candy Boss/candy-win.png")
		3:
			pass
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
