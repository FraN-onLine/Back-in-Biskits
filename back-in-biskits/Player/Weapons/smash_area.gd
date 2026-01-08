extends Area2D
class_name SmashArea

@export var damage: int = 0

var hit_bodies: Array = []

func _ready() -> void:
	monitoring = false
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	# Prevent double hits in one smash
	if body in hit_bodies:
		return

	# Basic enemy check
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
			hit_bodies.append(body)

func reset_hits() -> void:
	hit_bodies.clear()
