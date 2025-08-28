extends CharacterBody2D
class_name Player

var PopupScene = preload("res://Pickup/Pickup UI/popup.tscn")

@export var speed: float = 200.0
@export var attack_cooldown: float = 0.6
@export var graham_bullet: PackedScene
var can_attack: bool = true
var current_attack: String = "basic"
var cookie_potency = 1
var dead = false

@onready var anim: AnimatedSprite2D = $Sprite2D # reference to sprite
@onready var swordanim = $AnimatedSprite2D

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
	if dead: return
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
			swordanim.flip_h = input_dir.x > 0
		var shape = $LionCrackerSword/CollisionShape2D
		var pos = shape.position
		pos.x = abs(pos.x) * (-1 if input_dir.x < 0 else 1)
		shape.position = pos


# ---------------- Attacks ----------------
func perform_attack() -> void:
	can_attack = false

	match current_attack:
		"lion_cracker":
			sword_attack()
		"graham":
			graham_attack()

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
	anim.modulate = Color(1, 0.5, 0.5)
	dead = true
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://Screens/title_screen.tscn")


# -------------- Various Attacks ----------------


func sword_attack() -> void:
	$LionCrackerSword.damage = ((cookie_potency - 1) * 8) + 20
	var sword = $LionCrackerSword
	swordanim.visible = true
	sword.monitoring = true
	sword.visible = true
	swordanim.play("attack")
	await swordanim.animation_finished
	sword.monitoring = false
	sword.visible = false
	swordanim.visible = false
	
func graham_attack() -> void:
	if not graham_bullet: return

	var mouse_pos = get_global_mouse_position()
	var base_dir = (mouse_pos - global_position).normalized()
	var potency = cookie_potency

	match potency:
		1:
			_spawn_graham(global_position, base_dir, 7.5)
		2:
			# front + back
			_spawn_graham(global_position, base_dir, 10)
			_spawn_graham(global_position, base_dir.rotated(deg_to_rad(30)), 12.5)
		_:
			# potency 3+
			_spawn_graham(global_position, base_dir, 12.5)
			_spawn_graham(global_position, base_dir.rotated(deg_to_rad(30)), 15.0)
			_spawn_graham(global_position, base_dir.rotated(deg_to_rad(-30)), 15.0)

func _spawn_graham(pos: Vector2, dir: Vector2, dmg: float) -> void:
	var b = graham_bullet.instantiate()
	get_tree().current_scene.add_child(b)
	b.init(pos, dir, dmg)


# ---------------- Cookie Pickup ----------------
func pickup_cookie(cookie_type: String) -> void:
	current_attack = cookie_type
	print("Picked up cookie! Attack changed to: %s: %d" % [cookie_type, cookie_potency])
	cookie_potency = Global.potency
	await get_tree().create_timer(0.1).timeout
	if Global.potency > 1:
		Global.potency -= 1

func show_cookie_pickup(display_name: String, icon_tex: Texture2D) -> void:
	display_name = display_name + " %d" % Global.potency
	var popup = PopupScene.instantiate()
	add_child(popup)  # attach popup to player so it follows them
	popup.setup(display_name, icon_tex)
