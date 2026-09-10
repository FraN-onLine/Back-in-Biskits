extends CharacterBody2D
class_name CandyQueen

var boss_name = "Candy Connosieur"
@export var max_hp: int = 780
var current_hp: int = max_hp

@export var minion_scene: PackedScene
@export var projectile_scene: PackedScene
@export var barrage_textures: Array[Texture2D]   # assign in inspector

@export var summon_interval: float = 8.5
@export var teleport_interval: float = 8.0
@export var barrage_interval: float = 12
@export var barrage_shots: int = 10
@export var barrage_width: float = 600.0

var player: Node2D = null
var phase: int = 1
var alive: bool = true
var _squashing := false
var healthbar : Node
@export var damage_popup_scene : PackedScene

@onready var teleport_markers: Array[Node]
@onready var spawn_points: Array[Node]
@onready var barrage_markers: Array[Node]

func _ready() -> void:
	# Add this boss to the bosses group for waypoint tracking
	add_to_group("bosses")
	healthbar = $"../UI".get_node("Healthbar")
	healthbar.init_health(max_hp)
	current_hp = max_hp
	teleport_markers = get_tree().get_nodes_in_group("candyqueen_teleport")
	spawn_points = get_tree().get_nodes_in_group("candyqueen_minion")
	barrage_markers = get_tree().get_nodes_in_group("candyqueen_barrage")
	player = get_tree().get_first_node_in_group("player")
	Global.warning_enabled = false
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
	await $AnimatedSprite2D.animation_finished
	$AnimatedSprite2D.play("idle")

	if spawn_points.size() == 0:
		return

	# Pick a random marker
	var spot: Marker2D = spawn_points.pick_random()

	# Spawn minion at marker position
	var minion = minion_scene.instantiate()
	get_tree().current_scene.add_child(minion)
	minion.global_position = spot.global_position


func teleport_loop() -> void:
	if !alive or phase != 1:
		return
		print("teleporty")
	if teleport_markers.size() > 0:
		var spot: Marker2D = teleport_markers.pick_random()
		global_position = spot.global_position
	await get_tree().create_timer(teleport_interval).timeout
	teleport_loop()


# ----------------- PHASE 2 -----------------
func start_phase_2() -> void:
	phase = 2
	barrage_loop()


func barrage_loop() -> void:
	if !alive or phase != 2:
		return
	barrage_attack()
	await get_tree().create_timer(barrage_interval).timeout
	barrage_loop()


func barrage_attack() -> void:
	Global.warning_enabled = true
	print("🍬 Candy Queen candy barrage!")
	if not projectile_scene or barrage_markers.is_empty():
		return
	
	$AnimatedSprite2D.play("summon") # plays summon animation
	await $AnimatedSprite2D.animation_finished
	$AnimatedSprite2D.play("idle")

	for i in range(barrage_shots):
		var projectile = projectile_scene.instantiate()
		get_tree().current_scene.add_child(projectile)

		# Pick one of the 3 spawn markers
		var spot: Marker2D = barrage_markers.pick_random()
		projectile.global_position = spot.global_position

		# Straight down
		projectile.direction = Vector2.DOWN
		projectile.speed = 250

		# Assign random candy texture
		if barrage_textures.size() > 0:
			var tex = barrage_textures.pick_random()
			projectile.set_texture(tex)

		await get_tree().create_timer(0.6).timeout  # stagger rain
		
	Global.warning_enabled = false



# ----------------- DAMAGE -----------------
func take_damage(amount: int) -> void:
	if not alive:
		return
	current_hp -= amount
	healthbar.set_health(current_hp)
	_register_player_hit()
	
	# --- Game feel: hit-stop, squash, directional shake on the landing hit ---
	Global.hitstop(0.05)
	_squash()
	if player and is_instance_valid(player) and player.has_method("shake_camera"):
		player.shake_camera(0.4, (global_position - player.global_position).normalized())
	
	if damage_popup_scene:
		var popup := damage_popup_scene.instantiate()
		get_tree().current_scene.add_child(popup)
		var jitter_x := randf_range(-6, 6)
		popup.show_damage(amount, global_position + Vector2(jitter_x, -20))
	
	$AnimatedSprite2D.modulate = Color(1, 0.5, 0.5) # flash red
	await get_tree().create_timer(0.1).timeout
	$AnimatedSprite2D.modulate = Color(1, 1, 1)

	if current_hp <= 380 and phase == 1:
		start_phase_2()

	if current_hp <= 0:
		die()


func die() -> void:
	alive = false
	$AnimatedSprite2D.play("death")
	_freeze_stopwatch()
	_record_best_time(2)
	# Frame-crunch on the finishing blow, then brief slow-mo before K.O.
	await Global.hitstop(0.12)
	await Global.kill_slowmo(0.45, 0.18)
	await $AnimatedSprite2D.animation_finished
	await _ko_grace()
	Global.stage = 3
	Global.potency = 1
	Global.timer = 0
	Global.shield = 0
	Global.warning_enabled = false
	FadeManager.fade_out_then_change_scene("res://Areas/hallway_3.tscn")

func _freeze_stopwatch() -> void:
	var ui_node = get_tree().get_first_node_in_group("ui")
	if ui_node and ui_node.has_method("get_stopwatch_time"):
		Global.last_fight_time = ui_node.get_stopwatch_time()
	if ui_node and ui_node.has_method("stop_stopwatch"):
		ui_node.stop_stopwatch()

func _ko_grace() -> void:
	var ui_node = get_tree().get_first_node_in_group("ui")
	if ui_node and ui_node.has_method("show_ko"):
		await ui_node.show_ko()

# Squash-and-snap the sprite so hits visibly land.
func _squash() -> void:
	if _squashing:
		return
	_squashing = true
	var sprite: Node2D = $AnimatedSprite2D
	var base := sprite.scale
	sprite.scale = base * Vector2(1.1, 0.9)
	await get_tree().create_timer(0.05).timeout
	if is_instance_valid(sprite):
		sprite.scale = base * Vector2(1.05, 0.95)
		await get_tree().create_timer(0.07).timeout
	if is_instance_valid(sprite):
		sprite.scale = base
	_squashing = false

func _register_player_hit() -> void:
	var p = get_tree().get_first_node_in_group("player")
	if p and p.has_method("register_hit"):
		p.register_hit()

func _record_best_time(stage: int) -> void:
	# Guard against the tree being torn down (e.g. a second die() racing a
	# scene change) which made get_tree() return null.
	if not is_instance_valid(get_tree()):
		return
	var ui_node = get_tree().get_first_node_in_group("ui")
	if ui_node and ui_node.has_method("get_stopwatch_time"):
		Global.submit_best_time(stage, ui_node.get_stopwatch_time())
