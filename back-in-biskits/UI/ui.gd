extends CanvasLayer
var blink = false

func _process(delta: float) -> void:
	$TextureRect.size.x = Global.lives * 32
	$Label.text = "Potency: " + str(Global.potency)
	$PotencyRect.size.x = Global.potency * 32
	if Global.potency == 3 and Global.timer >= 5 and blink == false:
		blink = true
		$PotencyRect.modulate = Color(1, 0.5, 0.5)  # light red
		await get_tree().create_timer(1.2).timeout
		$PotencyRect.modulate = Color(1, 1, 1)
		blink = false
	if Global.potency == 3 and Global.timer >= 9.5:
		$PotencyRect.modulate = Color(1, 1, 1)
	if Global.lives == 0:
		$TextureRect.visible = false
	if Global.potency == 0:
		$PotencyRect.visible = false
	else:
		$PotencyRect.visible = true
		#btw potency can reach 0, 0 potency means all buffs are null and void
		# so dont eat too much or else ull suffer doing nothing
		
	
