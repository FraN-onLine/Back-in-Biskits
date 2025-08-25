extends CanvasLayer

func _process(delta: float) -> void:
	$TextureRect.size.x = Global.lives * 32
