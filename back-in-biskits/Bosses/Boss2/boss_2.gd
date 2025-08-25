extends CharacterBody2D
class_name CandyQueen

@export var max_hp: int = 500
var hp: int = max_hp

@export var minion_scene: PackedScene
@export var projectile_scene: PackedScene

@export var summon_interval: float = 3.0
@export var attack_interval: float = 5.0
@export var stomp_range: float = 150.0   # Distance for AoE stomp
@export var barrage_shots: int = 6

var player: Node = null
var phase: int = 1
var alive: bool = true

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")  # assumes Player is in "player" group
	start_phase_1()


func start_phase_1() -> void:
	phase = 1
	summon_minions()


func summon_minions() -> void:
	if phase != 1 or not alive:
		return
	var minion = minion_scene.instantiate()
	get_parent().add_child(minion)
	minion.global_position = global_position + Vector2(randf_range(-100,100), randf_range(-100,100))
	await get_tree().create_timer(summon_interval).timeout
	summon_minions()   # keep summoning


func start_phase_2() -> void:
	phase = 2
	phase_2_attack()


func phase_2_attack() -> void:
	if phase != 2 or not alive:
		return
	if player == null:
		return

	var distance = global_position.distance_to(player.global_position)

	if distance <= stomp_range:
		stomp_attack()
	else:
		barrage_attack()

	await get_tree().create_timer(attack_interval).timeout
	phase_2_attack()


# --- Attacks ---
func stomp_attack() -> void:
	print("🍬 Candy Queen stomps!")
	var distance = global_position.distance_to(player.global_position)
	if distance <= stomp_range:
		player.call("take_damage", 1)


func barrage_attack() -> void:
	print("🍬 Candy Queen candy barrage!")
	for i in range(barrage_shots):
		var projectile = projectile_scene.instantiate()
		get_parent().add_child(projectile)
		projectile.global_position = global_position
		projectile.look_at(player.global_position)
		projectile.direction = (player.global_position - global_position).normalized()
		projectile.speed = 300
		await get_tree().create_timer(0.2).timeout  # stagger shots


# --- Damage handling ---
func take_damage(amount: int) -> void:
	if not alive:
		return
	hp -= amount
	print("Candy Queen HP: %d" % hp)

	if hp <= max_hp / 2 and phase == 1:
		start_phase_2()

	if hp <= 0:
		die()


func die() -> void:
	alive = false
	queue_free()
	print("Candy Queen defeated!")
