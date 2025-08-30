extends CharacterBody2D
class_name CandyQueen

@export var max_hp: int = 750
var hp: int = max_hp

@export var minion_scene: PackedScene
@export var projectile_scene: PackedScene
@export var barrage_textures: Array[Texture2D]   # assign in inspector

@export var summon_interval: float = 4.0
@export var teleport_interval: float = 8.0
@export var barrage_interval: float = 6.0
@export var barrage_shots: int = 12
@export var barrage_width: float = 600.0

var player: Node2D = null
var phase: int = 1
var alive: bool = true

@onready var teleport_markers: Array[Marker2D] = get_tree().get_nodes_in_group("candyqueen_teleports")

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	start_phase_1()


# ----------------- PHASE 1 -----------------
func start_phase_1() -> void:
	phase = 1
	spawn_loop()
	teleport_loop()


func spawn_loop() -> void:
	if !alive or phase != 1:
		return
	summon_minion()
	await get_tree().create_timer(summon_interval).timeout
	spawn_loop()


func summon_minion() -> void:
	if not minion_scene:
		return
	$AnimatedSprite2D.play("summon") # plays summon animation
	var minion = minion_scene.instantiate()
	get_tree().current_scene.add_child(minion)
	minion.global_position = global_position + Vector2(randf_range(-100,100), randf_range(-100,100))


func teleport_loop() -> void:
	if !alive or phase != 1:
		return
	if teleport_markers.size() > 0:
		var spot: Marker2D = teleport_markers.pick_random()
		$AnimatedSprite2D.play("teleport")
		await $AnimatedSprite2D.animation_finished
		global_position = spot.global_position
	await get_tree().create_timer(teleport_interval).timeout
	teleport_loop()


# ----------------- PHASE 2 -----------------
func start_phase_2() -> void:
	phase = 2
	spawn_loop() # still summons minions
	barrage_loop()


func barrage_loop() -> void:
	if !alive or phase != 2:
		return
	barrage_attack()
	await get_tree().create_timer(barrage_interval).timeout
	barrage_loop()


func barrage_attack() -> void:
	print("🍬 Candy Queen candy barrage!")
	if not projectile_scene:
		return

	for i in range(barrage_shots):
		var projectile = projectile_scene.instantiate()
		get_tree().current_scene.add_child(projectile)

		# Random X position across the map width
		var x_pos = randf_range(global_position.x - barrage_width/2, global_position.x + barrage_width/2)
		projectile.global_position = Vector2(x_pos, global_position.y - 400) # spawn above screen

		# Straight down
		projectile.direction = Vector2.DOWN
		projectile.speed = 250

		# Random candy sprite
		if barrage_textures.size() > 0 and projectile.has_node("Sprite2D"):
			projectile.get_node("Sprite2D").texture = barrage_textures.pick_random()

		await get_tree().create_timer(0.15).timeout # staggered rain


# ----------------- DAMAGE -----------------
func take_damage(amount: int) -> void:
	if not alive:
		return
	hp -= amount
	print("Candy Queen HP: %d" % hp)

	if hp <= 350 and phase == 1:
		start_phase_2()

	if hp <= 0:
		die()


func die() -> void:
	alive = false
	$AnimatedSprite2D.play("death")
	await $AnimatedSprite2D.animation_finished
	queue_free()
	print("Candy Queen defeated!")
