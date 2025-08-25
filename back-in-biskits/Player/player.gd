extends CharacterBody2D

class_name Player

@export var speed: float = 200.0
@export var attack_cooldown: float = 0.5

var can_attack: bool = true

# --- Current attack type (default = basic)
var current_attack: String = "basic"

# Input mapping (make sure you set these in Project Settings > Input Map)
# "move_up", "move_down", "move_left", "move_right"
# "attack" -> set to Right Mouse Button
# "pickup" -> optional (usually just body_entered signal)
func _process(delta: float) -> void:
	handle_movement(delta)

	if Input.is_action_just_pressed("attack") and can_attack:
		perform_attack()


func handle_movement(delta: float) -> void:
	var input_dir = Vector2.ZERO
	input_dir.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir = input_dir.normalized()

	velocity = input_dir * speed
	move_and_slide()


# --- Attack handling
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
	print("Basic Attack: Swing cookie staff")


func fire_attack() -> void:
	print("🔥 Fire Cookie Attack: Fireball launched!")


func ice_attack() -> void:
	print("❄ Ice Cookie Attack: Freeze blast!")


# --- Called when colliding with a cookie pickup
func pickup_cookie(cookie_type: String) -> void:
	current_attack = cookie_type
	print("Picked up cookie! Attack changed to: %s" % cookie_type)
