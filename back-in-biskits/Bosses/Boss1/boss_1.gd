extends CharacterBody2D

@export var hp: int = 300
@export var move_speed: float = 120.0
@export var float_height: float = 120.0
@export var float_range: float = 80.0
@export var shoot_interval: float = 1.5
@export var projectile_scene: PackedScene
@export var tracking_projectile_scene: PackedScene

var player: Node2D
var shoot_timer := 0.0
var phase2 := false

func _ready():
	player = get_tree().get_root().get_node("back-in-biskits/Player/player") # Adjust path if needed

func _physics_process(delta):
	if not player:
		return

	# Floating randomly above player
	var target_pos = player.global_position + Vector2(randf_range(-float_range, float_range), -float_height)
	var direction = (target_pos - global_position).normalized()
	var velocity = direction * move_speed

	var collision = move_and_collide(velocity * delta)
	if collision:
		velocity = Vector2.ZERO

	# Shooting logic
	shoot_timer -= delta
	if shoot_timer <= 0:
		shoot_timer = shoot_interval
		if hp > 100:
			shoot_projectile()
		else:
			if not phase2:
				phase2 = true
				shoot_radial_projectiles()
			shoot_projectile()

func shoot_projectile():
	# Randomly choose projectile type
	var use_tracking = randi() % 2 == 0
	var proj = tracking_projectile_scene if use_tracking else projectile_scene.instantiate()
	proj.global_position = global_position
	if use_tracking and proj.has_method("set_target"):
		proj.set_target(player)
	get_parent().add_child(proj)

func shoot_radial_projectiles():
	var count = 16
	for i in range(count):
		var angle = i * TAU / count
		var proj = projectile_scene.instantiate()
		proj.global_position = global_position
		proj.rotation = angle
		if proj.has_method("set_direction"):
			proj.set_direction(Vector2(cos(angle), sin(angle)))
		get_parent().add_child(proj)

func take_damage(amount):
	hp -= amount
	if hp <= 0:
		queue_free()
