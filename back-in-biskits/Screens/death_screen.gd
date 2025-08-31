extends Control

@onready var menu = $Menu
@onready var retry = $Retry

func _ready():
	menu.pressed.connect(_on_menu_pressed)
	retry.pressed.connect(_on_retry_pressed)
	match Global.stage:
		1:
			$boss_1/Label.text = "Eat my cat shit bitch, 1 life is more than enough for a motherfucker like u HAHAHAHAHAHA 😂🫵"
			$boss_1/Sprite2D.texture = preload("res://Assets/Bosses/Cat Boss/Cat_Win.png")
		2:
			$boss_2/Label.text = "lady mf"
			$boss_2/Sprite2D.texture = preload("res://Assets/Bosses/Cat Boss/cat_atk.png")
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
