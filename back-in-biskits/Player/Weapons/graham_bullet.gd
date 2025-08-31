extends Area2D
class_name GrahamBullet

var speed: float = 300.0
var damage: float = 10.0
var direction: Vector2

func init(start_pos: Vector2, dir: Vector2, dmg: float) -> void:
	global_position = start_pos
	direction = dir.normalized()
	damage = dmg
	# Rotate sprite so "up" points in travel direction
	rotation = direction.angle() + (PI/2)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

	# Safety auto-remove if out of world
	if global_position.length() > 5000:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
	elif body.is_in_group("walls"):
		queue_free()
