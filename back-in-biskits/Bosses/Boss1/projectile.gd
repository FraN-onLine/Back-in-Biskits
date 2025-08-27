extends Area2D
class_name Projectile

var speed: float
var damage: int
var homing: bool
var direction: Vector2
var player: CharacterBody2D

func init(start_pos: Vector2, dir: Vector2, s: float, dmg: int, is_homing: bool) -> void:
	global_position = start_pos
	speed = s - 100 
	damage = dmg
	homing = is_homing
	direction = dir.normalized()
	player = get_tree().get_first_node_in_group("player")

	# Connect signal (needs a CollisionLayer setup in editor or via code)
	connect("body_entered", Callable(self, "_on_body_entered"))
	print("lol")

func _physics_process(delta: float) -> void:
	if homing and player:
		direction = (player.global_position - global_position).normalized()

	global_position += direction * speed * delta
	print(global_position)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.take_damage(damage)  # hurt player
	queue_free()  # remove on any hit
