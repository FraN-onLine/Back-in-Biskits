extends CharacterBody2D
class_name Player

var PopupScene = preload("res://Pickup/Pickup UI/popup.tscn")

@export var speed: float = 200.0
@export var attack_cooldown: float = 0.5
@export var graham_bullet: PackedScene


var can_attack: bool = true
var current_attack: String = "basic"

@onready var anim: AnimatedSprite2D = $Sprite2D # reference to sprite

signal health_changed(new_hp: int)  # notify UI when HP updates
signal player_died


func _ready() -> void:
	Global.lives = 5


func _process(delta: float) -> void:
	handle_movement(delta)

	if Input.is_action_just_pressed("attack") and can_attack:
		perform_attack()


# ---------------- Movement ----------------
func handle_movement(delta: float) -> void:
	var input_dir = Vector2.ZERO
	input_dir.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir = input_dir.normalized()

	velocity = input_dir * speed
	move_and_slide()

	# --- Animation handling ---
	if input_dir == Vector2.ZERO:
		# Idle
		if anim.animation != "idle":
			anim.play("idle")
	else:
		# Walking
		if anim.animation != "walk":
			anim.play("walk")

		# Flip horizontally if moving right
		if input_dir.x != 0:
			anim.flip_h = input_dir.x > 0



# ---------------- Attacks ----------------
func perform_attack() -> void:
	can_attack = false

	match current_attack:
		"lion_cracker":
			sword_attack()
		"graham":
			graham_attack()
		"fire_cookie":
			fire_attack()
		"ice_cookie":
			ice_attack()

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true




# ---------------- Damage & HP ----------------
func take_damage(amount: int = 1) -> void:
	$Sprite2D.modulate = Color(1, 0.5, 0.5)  # flash red
	await get_tree().create_timer(0.1).timeout
	$Sprite2D.modulate = Color(1, 1, 1)
	print("Player took damage! HP = %d" % Global.lives)
	Global.lives -= amount
	if Global.lives <= 0:
		die()


func die() -> void:
	print("💀 Player died")
	emit_signal("player_died")
	queue_free()  # remove player (or play animation first)


# -------------- Various Attacks ----------------


func sword_attack() -> void:
	print("Slash")


func fire_attack() -> void:
	print("🔥 Fireball!")


func ice_attack() -> void:
	print("❄ Ice Blast!")
	
func graham_attack() -> void:
	if not graham_bullet: return

	var mouse_pos = get_global_mouse_position()
	var base_dir = (mouse_pos - global_position).normalized()
	var potency = Global.potency

	match potency:
		1:
			_spawn_graham(global_position, base_dir, 10.0)
		2:
			# front + back
			_spawn_graham(global_position, base_dir, 12.5)
			_spawn_graham(global_position, -base_dir, 12.5)
		_:
			# potency 3+
			_spawn_graham(global_position, base_dir, 15.0)
			_spawn_graham(global_position, base_dir.rotated(deg_to_rad(30)), 15.0)
			_spawn_graham(global_position, base_dir.rotated(deg_to_rad(-30)), 15.0)

func _spawn_graham(pos: Vector2, dir: Vector2, dmg: float) -> void:
	var b = graham_bullet.instantiate()
	get_tree().current_scene.add_child(b)
	b.init(pos, dir, dmg)


# ---------------- Cookie Pickup ----------------
func pickup_cookie(cookie_type: String) -> void:
	current_attack = cookie_type
	print("Picked up cookie! Attack changed to: %s" % cookie_type)
	match cookie_type:
		"lion_cracker":
			pass
		"fire_cookie":
			anim.modulate = Color(1, 0.5, 0.5)  # light red
		"ice_cookie":
			anim.modulate = Color(0.5, 0.8, 1)  # light blue
	

func show_cookie_pickup(display_name: String, icon_tex: Texture2D) -> void:
	var popup = PopupScene.instantiate()
	add_child(popup)  # attach popup to player so it follows them
	popup.setup(display_name, icon_tex)
