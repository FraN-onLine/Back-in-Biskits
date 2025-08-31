extends CharacterBody2D
class_name CookieMonster

var boss_name = "Cookie Monster"
@export var max_hp: int = 750
var current_hp: int

@export var minion_scene: PackedScene
@export var projectile_scene: PackedScene
@export var barrage_textures: Array[Texture2D] # assign in inspector

@export var attack_interval: float = 2.0 # seconds between attacks
var attack_timer: Timer

var player: Node2D = null
var alive: bool = true
var healthbar: Node
@export var damage_popup_scene: PackedScene
var rng := RandomNumberGenerator.new()

@onready var spawn_points: Array[Node]
@onready var barrage_markers: Array[Node]
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	print("[CookieMonster] _ready called")
	add_to_group("bosses")
	healthbar = $"../UI".get_node("Healthbar")
	healthbar.init_health(max_hp)
	current_hp = max_hp
	spawn_points = get_tree().get_nodes_in_group("candyqueen_minion")
	barrage_markers = get_tree().get_nodes_in_group("candyqueen_barrage")
	player = get_tree().get_first_node_in_group("player")

	attack_timer = Timer.new()
	attack_timer.wait_time = attack_interval
	attack_timer.autostart = true
	attack_timer.one_shot = false
	add_child(attack_timer)
	attack_timer.timeout.connect(_on_attack_timeout)
	print("[CookieMonster] Timer created and started")


# ----------------- ATTACK LOGIC (like Boss 1) -----------------
func _on_attack_timeout() -> void:
	if !alive:
		return
	var anims = ["handfall", "swipe"]
	var chosen_anim = anims[rng.randi_range(0, anims.size() - 1)]

	# Disable all hitboxes first
	$SwipeHitbox.monitoring = false
	$HandfallHitbox.monitoring = false
	$HandfallHitbox/Slam1.disabled = true
	$HandfallHitbox/Slam2.disabled = true
	$HandfallHitbox/Slam3.disabled = true

	if chosen_anim == "swipe":
		anim_sprite.play("swipe")
		await get_tree().create_timer(0.5).timeout # charge-up
		$SwipeHitbox.monitoring = true
		await anim_sprite.animation_finished
		$SwipeHitbox.monitoring = false

	elif chosen_anim == "handfall":
		$HandfallHitbox.monitoring = true
		anim_sprite.play("handfall")
		# First slam
		await get_tree().create_timer(1.2).timeout
		$HandfallHitbox/Slam1.disabled = false
		await get_tree().create_timer(0.1).timeout
		$HandfallHitbox/Slam1.disabled = true

		# Second slam
		await get_tree().create_timer(0.4).timeout
		$HandfallHitbox/Slam2.disabled = false
		await get_tree().create_timer(0.1).timeout
		$HandfallHitbox/Slam2.disabled = true

		# Third slam
		await get_tree().create_timer(0.7).timeout
		$HandfallHitbox/Slam3.disabled = false
		await get_tree().create_timer(0.1).timeout
		$HandfallHitbox/Slam3.disabled = true

		await anim_sprite.animation_finished
		$HandfallHitbox.monitoring = false

	anim_sprite.play("idle")

	anim_sprite.play("idle")


# ----------------- DAMAGE -----------------
func take_damage(amount: int = 1) -> void:
	if not alive:
		return
	current_hp -= amount
	current_hp = max(current_hp, 0)
	healthbar.set_health(current_hp)
	
	if damage_popup_scene:
		var popup := damage_popup_scene.instantiate()
		get_tree().current_scene.add_child(popup)
		var jitter_x := randf_range(-6, 6)
		popup.show_damage(amount, global_position + Vector2(jitter_x, -20))
	
	anim_sprite.modulate = Color(1, 0.5, 0.5) # flash red
	await get_tree().create_timer(0.1).timeout
	anim_sprite.modulate = Color(1, 1, 1)
	if current_hp <= 0:
		die()


func die() -> void:
	alive = false
	anim_sprite.play("death")
	$CollisionShape2D.disabled = true
	await anim_sprite.animation_finished
	Global.stage = 3
	Global.potency = 1
	Global.timer = 0
	get_tree().change_scene_to_file("res://Areas/area_2.tscn")


func _on_swipe_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(1) # Adjust damage as needed


func _on_handfall_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(1) # Adjust damage as needed
