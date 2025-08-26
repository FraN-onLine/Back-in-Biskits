extends Node2D

@onready var icon: Sprite2D = $Icon
@onready var label: Label = $Label

# Called after instancing
func setup(display_name: String, icon_tex: Texture2D) -> void:
	icon.texture = icon_tex
	label.text = display_name

	# Reset alpha and position for animation
	self.modulate.a = 1.0
	self.position = Vector2(0, -20)  # appear above player's head

	# Tween: rise up + fade out
	var tween = create_tween()
	tween.tween_property(self, "position:y", self.position.y - 20, 1.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 1.0)

	await tween.finished
	queue_free()
