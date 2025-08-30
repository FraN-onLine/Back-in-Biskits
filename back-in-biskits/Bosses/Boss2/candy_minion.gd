extends CharacterBody2D
class_name CandyMinion

@export var speed: float = 100.0
@export var max_hp: int = 50
@export var aoe_damage: int = 1
@export var aoe_radius: float = 40.0
@export var attack_interval: float = 2.0

var hp: int
var player: Node2D = null
var alive: bool = true

var attack_timer: Timer

func _ready() -> void:
	hp = max_hp
	player = get_tree().get_first_node_in_group("player")

	# attack timer
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_interval
	attack_timer.one_shot = false
	attack_timer.autostart = true
	add_child(attack_timer)
	attack_timer.timeout.connect(_on_attack_timeout)


func _physics_process(delta: float) -> void:
	if not alive or player == null:
		return

	# chase player
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()


func _on_attack_timeout() -> void:
	if not alive or player == null:
		return

	# check if player is in AoE circle
	if global_position.distance_to(player.global_position) <= aoe_radius:
		print("💥 Minion AoE hit player!")
		#wait 0.5 seconds to sync with animation
		$AnimatedSprite2D.play("attack")
		await get_tree().create_timer(0.6).timeout
		
		
		player.call("take_damage", aoe_damage)




# ---------------- DAMAGE ----------------
func take_damage(amount: int) -> void:
	if not alive:
		return
	hp -= amount
	$AnimatedSprite2D.modulate = Color(1, 0.5, 0.5) # flash red
	await get_tree().create_timer(0.2).timeout
	$AnimatedSprite2D.modulate = Color(1, 1, 1)
	print("Minion HP: %d" % hp)

	if hp <= 0:
		die()


func die() -> void:
	alive = false
	queue_free()
