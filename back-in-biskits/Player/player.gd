extends CharacterBody2D
class_name Player

@export var speed: float = 200.0
@export var attack_cooldown: float = 0.5
@export var max_hp: int = 5   # max health
var current_hp: int

var can_attack: bool = true
var current_attack: String = "basic"

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


# ---------------- Attacks ----------------
func perform_attack() -> void:
	can_attack = false

	match current_attack:
		"basic":
			basic_attack()
		"fire_cookie":
			fire_attack()
		"ice_cookie":
			ice_attack()
		_:
			basic_attack()

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true


func basic_attack() -> void:
	print("Basic Attack")


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
	
func show_cookie_pickup(display_name: String, icon_tex: Texture2D) -> void:
	# Container for popup
	var popup = Node2D.new()
	popup.position = Vector2(0, -40)   # directly above player's head
	add_child(popup)

	# Icon (small, centered)
	var icon = Sprite2D.new()
	icon.texture = icon_tex
	icon.centered = true
	icon.scale = Vector2(0.5, 0.5)   # shrink to 30%
	icon.position = Vector2(0, -12)  # just above text
	popup.add_child(icon)

	# Label (centered under icon)
	var label = Label.new()
	label.text = display_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(0, 8)

	# Load your Silkscreen font
	var font = preload("res://Assets/Fonts/Silkscreen-Regular.ttf")
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 10)

	popup.add_child(label)

	# --- Tween the WHOLE popup ---
	popup.modulate.a = 1.0
	var tween = popup.create_tween()
	tween.tween_property(popup, "position:y", popup.position.y - 20, 1.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "modulate:a", 0.0, 1.0)  # fade entire popup together

	await tween.finished
	popup.queue_free()
