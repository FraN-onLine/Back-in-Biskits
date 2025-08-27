extends Area2D
class_name Projectile

var speed: float
var damage: int
var homing: bool
var direction: Vector2
var player: CharacterBody2D
@export var homing_texture: Texture2D

func init(start_pos: Vector2, dir: Vector2, s: float, dmg: int, is_homing: bool) -> void:
	global_position = start_pos
	speed = s - 100
	damage = dmg
	homing = is_homing
	direction = dir.normalized()
	player = get_tree().get_first_node_in_group("player")

	# Make sure collision signal only connects once
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))


func _physics_process(delta: float) -> void:
	if homing and player:
		$Sprite2D.texture = homing_texture
		direction = (player.global_position - global_position).normalized()
		$Sprite2D.rotation = direction.angle() + PI + PI / 8
	if not homing:
		$Sprite2D.rotation = direction.angle() + PI + PI / 16
	

	global_position += direction * speed * delta


func _on_body_entered(body: Node) -> void:
	# ✅ Only damage player
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()

	# ✅ If it hits walls/tiles → destroy
	elif body.is_in_group("walls"): 
		queue_free()

	# ❌ Ignore bosses, enemies, cookies
