extends CharacterBody2D
class_name Player

var PopupScene = preload("res://Pickup/Pickup UI/popup.tscn")

@export var speed: float = 200.0
@export var attack_cooldown: float = 0.5
@export var max_hp: int = 5   # max health
var current_hp: int

var can_attack: bool = true
var current_attack: String = "basic"

@onready var anim: AnimatedSprite2D = $Sprite2D # reference to sprite

signal health_changed(new_hp: int)  # notify UI when HP updates
signal player_died


func _ready() -> void:
	current_hp = max_hp
	emit_signal("health_changed", current_hp)


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
		"fire_cookie":
			fire_attack()
		"ice_cookie":
			ice_attack()

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true


func sword_attack() -> void:
	print("Slash")


func fire_attack() -> void:
	print("🔥 Fireball!")


func ice_attack() -> void:
	print("❄ Ice Blast!")


# ---------------- Damage & HP ----------------
func take_damage(amount: int = 1) -> void:
	current_hp -= amount
	current_hp = clamp(current_hp, 0, max_hp)
	emit_signal("health_changed", current_hp)

	print("Player took damage! HP = %d" % current_hp)

	if current_hp <= 0:
		die()


func die() -> void:
	print("💀 Player died")
	emit_signal("player_died")
	queue_free()  # remove player (or play animation first)


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
