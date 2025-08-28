extends CanvasLayer
var blink = false

func _process(delta: float) -> void:
	$TextureRect.size.x = Global.lives * 32
	$Label.text = "Potency: " + str(Global.potency)
	$PotencyRect.size.x = Global.potency * 32
	if Global.potency == 3 and Global.timer >= 5 and blink == false:
		blink = true
		$PotencyRect.modulate = Color(1, 0.5, 0.5)  # light red
		await get_tree().create_timer(0.8).timeout
		$PotencyRect.modulate = Color(1, 1, 1)
		blink = false
	if Global.potency == 3 and Global.timer >= 9.5:
		$Global.potencyRect.modulate = Color(1, 1, 1)
		
		
	
