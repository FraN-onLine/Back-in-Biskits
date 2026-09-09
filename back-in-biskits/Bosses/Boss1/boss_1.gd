extends CharacterBody2D
class_name CookieBoss

var boss_name = "Calico Cookie-Cat"
@onready var blueatk = $AudioStreamPlayer 
@onready var redatk = $AudioStreamPlayer2
@onready var circleatk = $AudioStreamPlayer3
@export var speed: float = 120.0
@export var max_hp: int = 420
var current_hp: int
@export var projectile: PackedScene
@export var damage_popup_scene: PackedScene
var radial_used: bool = false
var dead = false
var _squashing := false

@export var attack_interval: float = 2.0 # seconds between attacks
var attack_timer: Timer

var player: Node2D
var rng := RandomNumberGenerator.new()

var hover_target: Vector2
var hover_update_timer: float = 0.0
var healthbar: Node
signal boss_died


func _ready() -> void:
	# Add this boss to the bosses group for waypoint tracking
	add_to_group("bosses")
	healthbar = $"../UI".get_node("Healthbar")
	healthbar.init_health(max_hp)
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
	if player == null or dead:
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
	hover_update_timer = 1.5 # update every 1.5s


# ---------------- Attacks ----------------
func _on_attack_timeout() -> void:
	$AnimatedSprite2D.play("attack")
	if current_hp > 250:
		# Randomly choose projectile type
		if rng.randi_range(0, 1) == 0:
			shoot_standard()
		else:
			shoot_homing()
	else:
		attack_interval = 1.5 # faster attacks
		# Still does normal attacks, but also radial burst at 100 hp
		if radial_used == false:
			radial_used = true
			radial_burst()
		else:
			shoot_standard()
		if current_hp < 101 and current_hp > 50:
			radial_used = false
	await $AnimatedSprite2D.animation_finished
	$AnimatedSprite2D.play("default")
	
func shoot_standard() -> void:
	var dir = (player.global_position - global_position).normalized()
	var proj = projectile.instantiate()
	get_tree().current_scene.add_child(proj)
	blueatk.play()
	proj.init(global_position, dir, 210, 1, false) # speed, damage, not homing
	

func shoot_homing() -> void:
	var proj = projectile.instantiate()
	get_tree().current_scene.add_child(proj)
	redatk.play()
	proj.init(global_position, Vector2.ZERO, 184, 1, true) # homing
	

func radial_burst() -> void:
	var count = 16
	for i in range(count):
		var angle = (TAU / count) * i
		var dir = Vector2.RIGHT.rotated(angle)
		var proj = projectile.instantiate()
		get_tree().current_scene.add_child(proj)
		circleatk.play()
		proj.init(global_position, dir, 220, 1, false)
		

# ---------------- Damage ----------------
func take_damage(amount: int = 1) -> void:
	current_hp -= amount
	current_hp = max(current_hp, 0)
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
	if current_hp <= 0:
		die()


func die() -> void:
	$AnimatedSprite2D.play("death")
	$CollisionShape2D.disabled = true
	velocity = Vector2.ZERO
	dead = true
	_record_best_time(1)
	emit_signal("boss_died")
	# Frame-crunch on the finishing blow, then brief slow-mo before K.O.
	await Global.hitstop(0.12)
	await Global.kill_slowmo(0.45, 0.18)
	await $AnimatedSprite2D.animation_finished
	await _ko_grace()
	Global.stage = 2
	Global.potency = 1
	Global.timer = 0
	Global.shield = 0
	FadeManager.fade_out_then_change_scene("res://Areas/hallway_2.tscn")

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
