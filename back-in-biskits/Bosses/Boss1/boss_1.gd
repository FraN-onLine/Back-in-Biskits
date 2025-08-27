extends CharacterBody2D
class_name CookieBoss

@export var speed: float = 120.0
@export var max_hp: int = 300
var current_hp: int
@export var projectile: PackedScene

@export var attack_interval: float = 2.0   # seconds between attacks
var attack_timer: Timer

var player: Node2D
var rng := RandomNumberGenerator.new()

var hover_target: Vector2
var hover_update_timer: float = 0.0

signal boss_died


func _ready() -> void:
	current_hp = max_hp
	player = get_tree().get_first_node_in_group("player")

	# Attack timer
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_interval
	attack_timer.autostart = true
	attack_timer.one_shot = false
	add_child(attack_timer)
	attack_timer.timeout.connect(_on_attack_timeout)

	# Set initial hover target
	_set_new_hover_target()


func _physics_process(delta: float) -> void:
	if player == null:
		return

	# Update hover target every 1.5 sec for smoother movement
	hover_update_timer -= delta
	if hover_update_timer <= 0:
		_set_new_hover_target()

	# Move towards hover target
	var direction = (hover_target - global_position).normalized()
	velocity = direction * speed

	# --- Ceiling check ---
	var space_state = get_world_2d().direct_space_state
	var ray_from = global_position
	var ray_to = global_position + Vector2(0, -40)
	var query = PhysicsRayQueryParameters2D.create(ray_from, ray_to)
	var result = space_state.intersect_ray(query)

	if not result.is_empty() and velocity.y < 0:
		velocity.y = 0

	move_and_slide()


func _set_new_hover_target() -> void:
	if player == null: return
	# Keep consistent offset above player for a while
	var offset = Vector2(rng.randf_range(-80, 80), -100)
	hover_target = player.global_position + offset
	hover_update_timer = 1.5   # update every 1.5s




# ---------------- Attacks ----------------
func _on_attack_timeout() -> void:
	if current_hp > 100:
		# Randomly choose projectile type
		if rng.randi_range(0, 1) == 0:
			shoot_standard()
		else:
			shoot_homing()
	else:
		# Still does normal attacks, but also radial burst at 100 hp
		if current_hp == 100:
			radial_burst()
		else:
			shoot_standard()


func shoot_standard() -> void:
	var dir = (player.global_position - global_position).normalized()
	var proj = projectile.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.init(global_position, dir, 210, 1, false) # speed, damage, not homing
	


func shoot_homing() -> void:
	var proj = projectile.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.init(global_position, Vector2.ZERO, 176, 1, true) # homing
	


func radial_burst() -> void:
	var count = 16
	for i in range(count):
		var angle = (TAU / count) * i
		var dir = Vector2.RIGHT.rotated(angle)
		var proj = projectile.new()
		proj.init(global_position, dir, 220, 1, false)
		get_tree().current_scene.add_child(proj)


# ---------------- Damage ----------------
func take_damage(amount: int = 1) -> void:
	current_hp -= amount
	current_hp = max(current_hp, 0)

	if current_hp <= 0:
		die()


func die() -> void:
	emit_signal("boss_died")
	queue_free()
