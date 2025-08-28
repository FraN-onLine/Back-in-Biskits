extends Node

var lives = 5
var potency = 1
var timer = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer += delta
	if timer >= 10.0:
		timer = 0.0
		if potency < 3:
			potency += 1
		elif potency == 3:
			lives -= 1
