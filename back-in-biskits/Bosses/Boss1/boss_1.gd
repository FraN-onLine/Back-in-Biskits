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

signal boss_died


func _ready() -> void:
	current_hp = max_hp

	# Find the player (assuming there's only one)
	player = get_tree().get_first_node_in_group("player")

	# Attack timer
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_interval
	attack_timer.autostart = true
	attack_timer.one_shot = false
	add_child(attack_timer)
	attack_timer.timeout.connect(_on_attack_timeout)


func _physics_process(delta: float) -> void:
	if player == null: return

	# Target position: randomly offset *above* player
	var target_offset = Vector2(rng.randf_range(-100, 100), -rng.randf_range(60, 120))
	var target_pos = player.global_position + target_offset

	var direction = (target_pos - global_position).normalized()
	velocity = direction * speed

	move_and_slide()


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
	proj.init(global_position, dir, 150, 1, false) # speed, damage, not homing
	


func shoot_homing() -> void:
	var proj = projectile.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.init(global_position, Vector2.ZERO, 120, 1, true) # homing
	


func radial_burst() -> void:
	var count = 16
	for i in range(count):
		var angle = (TAU / count) * i
		var dir = Vector2.RIGHT.rotated(angle)
		var proj = projectile.new()
		proj.init(global_position, dir, 120, 1, false)
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
