extends Control

@onready var menu = $Menu
@onready var retry = $Retry

func _ready():
	match Global.stage:
		1:
			$Label.text = "Captain, Captain? I thought we're just playing.. oh well"
			$Sprite2D.texture = preload("res://Assets/Bosses/Boss Portraits/Calico-win.png")
		2:
			$Label.text = "Crumbled and Cooked, such low caliber..."
			$Sprite2D.texture = preload("res://Assets/Bosses/Boss Portraits/Candy-win.png")
		3:
			$Label.text = "Crispy, "
			$Sprite2D.texture = preload("res://Assets/Bosses/Boss Portraits/Hotdoggier-win.png")
		4:
			$Label.text = "Cookie?- Was i too powerful little hero?"
			$Sprite2D.texture = preload("res://Assets/Bosses/Boss Portraits/Confectioneer-win.png")
		_:
			$Label.text = "C-Died? You were not supposed to die"
			$Sprite2D.texture = preload("res://Assets/Bosses/Boss Portraits/tutorial-win.png")

	# Best time + this run's time
	var best := Global.get_best_time(Global.stage)
	var best_text := Global.format_time(best) if best > 0.0 else "--:--"
	$TimeLabel.text = "RUN  %s   |   BEST  %s" % [Global.format_time(Global.last_death_time), best_text]

func _on_menu_pressed():
	get_tree().change_scene_to_file("res://Screens/title_screen.tscn")

func _on_retry_pressed():
	Global.potency = 1
	Global.timer = 0
	Global.shield = 0
	match Global.stage:
		1:
			get_tree().change_scene_to_file("res://Areas/area_1.tscn")
		2:
			get_tree().change_scene_to_file("res://Areas/area_2.tscn")
		3:
			get_tree().change_scene_to_file("res://Areas/area_3.tscn")
		4:
			get_tree().change_scene_to_file("res://Areas/area_4.tscn")
		_:
			get_tree().change_scene_to_file("res://Areas/tutorial.tscn")
