extends Area2D

func _ready():
	self.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player":
		FadeManager.fade_out_then_change_scene("res://Areas/area_1.tscn")
