extends Area2D
class_name PeanutBullet

var speed: float = 250.0
var damage: float = 8.0
var direction: Vector2
var potency: int = 1
var player_ref: Node = null

var outgoing_duration: float = 0.6
var return_duration: float = 0.7
var elapsed: float = 0.0
var returning: bool = false

func init(start_pos: Vector2, dir: Vector2, dmg: float, pot: int, player: Node) -> void:
	global_position = start_pos
	direction = dir.normalized()
	damage = dmg
	potency = pot
	player_ref = player
	
	# Durations based on potency (stage)
	match potency:
		1:
			outgoing_duration = 0.2
			return_duration = 0.4
		2:
			outgoing_duration = 0.5
			return_duration = 0.6
		3:
			outgoing_duration = 0.7
			return_duration = 0.8
	
	# Rotate sprite so "up" points in travel direction
	rotation = direction.angle() + (PI/2)


func _physics_process(delta: float) -> void:
	elapsed += delta
	
	if not returning:
		# Outgoing phase: fly toward aimed direction
		global_position += direction * speed * delta
		
		if elapsed >= outgoing_duration:
			# Time to return to player
			returning = true
			elapsed = 0.0
			# Recalculate direction toward player
			direction = (player_ref.global_position - global_position).normalized()
			rotation = direction.angle() + (PI/2)
	else:
		# Return phase: fly back toward player
		global_position += direction * speed * delta
		
		# Return early if close to player or time runs out
		if global_position.distance_to(player_ref.global_position) < 25 or elapsed >= return_duration:
			queue_free()
	
	# Safety auto-remove if out of world
	if global_position.length() > 5000:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		# Don't queue_free on enemy hit during outgoing - let it pass through
		# Only queue_free on enemy hit during return phase
		if returning:
			queue_free()
	elif body.is_in_group("player") and returning:
		# Collected by player on return
		queue_free()
	elif body.is_in_group("walls"):
		queue_free()
