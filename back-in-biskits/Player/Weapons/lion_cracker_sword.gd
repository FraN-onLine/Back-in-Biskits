extends Area2D

var damage = 20

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect("body_entered", Callable(self, "_on_sword_body_entered"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _on_sword_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		if body in get_parent().hit_enemies:
			return  # already hit this enemy this swing
		get_parent().hit_enemies.append(body)
		body.take_damage(damage)
