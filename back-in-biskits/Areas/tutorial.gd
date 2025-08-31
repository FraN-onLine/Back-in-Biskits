extends Node2D

@onready var skip = $UI/SkipButton

var potset0 = false
var potset3 = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Area2D.body_entered.connect(_on_body_entered_end)
	$SetPot0.body_entered.connect(_on_body_entered_p0)
	$SetPot3.body_entered.connect(_on_body_entered_p3)

func _on_body_entered_end(body):
	if body.name == "Player":
		$UI.visible = false
		FadeManager.fade_out_then_change_scene("res://Areas/area_1.tscn")
		Global.stage = 1
	Global.potency = 1
	Global.timer = 0
	
func _on_body_entered_p0(body):
	if body.name == "Player" and potset0 == false:
		Global.potency = 0
		Global.timer = 0
		potset0 = false
	
func _on_body_entered_p3(body):
	if body.name == "Player" and potset3 == false:
		Global.potency = 3
		Global.timer = 0
		potset3 = false

func _on_skip_button_pressed():
	FadeManager.fade_out_then_change_scene("res://Areas/area_1.tscn")
	Global.stage = 1
	Global.potency = 1
	Global.timer = 0
