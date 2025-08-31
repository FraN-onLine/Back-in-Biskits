extends Area2D
class_name CandyProjectile

@export var speed: float = 120
var direction: Vector2 = Vector2.DOWN
var damage: int = 1

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))

func _process(delta: float) -> void:
	position += direction * speed * delta

	# Free if out of screen
	if position.y > get_viewport_rect().size.y + 100:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()

func set_texture(tex: Texture2D) -> void:
	if tex:
		sprite.texture = tex
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, 32, 32)
