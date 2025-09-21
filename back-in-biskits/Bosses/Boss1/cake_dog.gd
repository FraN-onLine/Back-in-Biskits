extends CharacterBody2D

signal enemy_died

# --- Enemy Stats ---
var max_hp := 35
var hp := max_hp
var speed := 135                    # charging speed
var charge_interval := 3.5           # seconds between charges
var charge_duration := 0.5        # how long a charge lasts
var dir

# --- State ---
var player: Node2D = null
var charging := false
var alive := true
var timer := 0.0                     # internal timer for charge cooldown

# --- Nodes ---
@export var damage_popup_scene: PackedScene
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox


# ----------------- READY -----------------
func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	hitbox.body_entered.connect(_on_body_entered)
	anim.play("idle")  # start idle anim


# ----------------- LOOP -----------------
func _physics_process(delta: float) -> void:
	if not alive:
		return

	# Count down until next charge
	timer -= delta
	if timer <= 0 and not charging:
		start_charge()

	# Handle charging movement
	if charging and player:
		velocity = dir * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()


# ----------------- CHARGE LOGIC -----------------
func start_charge() -> void:
	if not player:
		return
	dir = (player.global_position - global_position).normalized()
	charging = true
	anim.play("attack")
	await get_tree().create_timer(charge_duration).timeout
	charging = false
	anim.play("idle")
	timer = charge_interval  # reset cooldown


# ----------------- COMBAT -----------------
func take_damage(amount: int) -> void:
	if not alive:
		return
	hp -= amount

	if damage_popup_scene:
		var popup := damage_popup_scene.instantiate()
		get_tree().current_scene.add_child(popup)
		var jitter_x := randf_range(-6, 6)
		popup.show_damage(amount, global_position + Vector2(jitter_x, -20))

	# Flash red
	anim.modulate = Color(1, 0.5, 0.5)
	await get_tree().create_timer(0.2).timeout
	anim.modulate = Color(1, 1, 1)

	print("Dummy HP: %d" % hp)

	if hp <= 0:
		die()


func die() -> void:
	alive = false
	anim.play("idle")  # or you can add a "death" anim
	emit_signal("enemy_died")
	queue_free()


func _on_body_entered(body: Node) -> void:
	if charging and body.is_in_group("player"):
		body.take_damage(1)
		charging = false
		anim.play("idle")
		timer = charge_interval
