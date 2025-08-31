extends Node

var lives = 5
var shield = 0
var potency = 1
var timer = 0.0
var stage = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer += delta
	if timer >= 6.5:
		timer = 0.0
		if potency < 3:
			potency += 1
		elif potency == 3:
			lives -= 1
			var player = get_tree().get_first_node_in_group("player")
			if player:
				player.get_node("Sprite2D").modulate = Color(1, 0.5, 0.5)
				await get_tree().create_timer(0.2).timeout
				player.get_node("Sprite2D").modulate = Color(1, 1, 1)
			
