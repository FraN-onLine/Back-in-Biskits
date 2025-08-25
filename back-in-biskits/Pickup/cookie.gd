extends Area2D

@export var cookie_type: String = "fire_cookie"

func _on_body_entered(body: Node) -> void:
	if body is Player:
		body.pickup_cookie(cookie_type)
		queue_free()  # Remove the cookie after pickup
