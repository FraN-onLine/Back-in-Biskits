extends Area2D
class_name Shockwave

@export var base_damage: int = 20
@export var lifetime: float = 0.4
var cookie_potency = 0
var oreoshockwave = false

func _ready() -> void:
	monitoring = true
	$CollisionShape2D.disabled = false
	
	
	# Damage any enemy already inside when spawned
	for body in get_overlapping_bodies():
		_on_body_entered(body)

	# Connect signal for new entries
	connect("body_entered", Callable(self, "_on_body_entered"))

	# Auto-remove after lifetime
	await get_tree().create_timer(lifetime).timeout
	queue_free()
	
func _process(delta: float) -> void:
	if oreoshockwave:
		$CollisionShape2D.scale = Vector2(0.8,0.8)
		$AnimatedSprite2D.scale = Vector2(0.8,0.8)

func _on_body_entered(body: Node) -> void:
	if not oreoshockwave:
		base_damage = (cookie_potency * 7.5) + 20 #35,42.5 hammer
	else:
		base_damage = (cookie_potency * 5) + 15 #25, 30 rush
	
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(base_damage)
