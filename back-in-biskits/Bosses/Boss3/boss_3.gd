extends CharacterBody2D
class_name CookieMonster

var boss_name = "Confectioneer"
@export var max_hp: int = 800
var current_hp: int

@export var minion_scene: PackedScene
@export var projectile_scene: PackedScene
@export var barrage_textures: Array[Texture2D]

@export var attack_interval: float = 5.8 # seconds between attacks

var shoot_cooldown: float = 0 # timer
var player: Node2D = null
var alive: bool = true
var healthbar: Node
@export var damage_popup_scene: PackedScene
var rng := RandomNumberGenerator.new()

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

var last_attack: String = ""


func _ready() -> void:
	add_to_group("bosses")
	healthbar = $"../UI".get_node("Healthbar")
	healthbar.init_health(max_hp)
	current_hp = max_hp
	player = get_tree().get_first_node_in_group("player")
	#zoom out to 2.5 scale and limit to 260 each side
	player.get_node("Camera2D").zoom = Vector2(2.5, 2.5)
	player.get_node("Camera2D").limit_left = -260
	player.get_node("Camera2D").limit_right = 260
	player.get_node("Camera2D").limit_top = -260
	player.get_node("Camera2D").limit_bottom = 260
	# Start attack loop
	attack_loop()

func _process(delta: float) -> void:
	if alive:
		shoot_cooldown += delta
		if shoot_cooldown > 5.5:
			shoot_cooldown = 0
			do_shoot()

# ----------------- ATTACK LOOP -----------------
func attack_loop() -> void:
	while alive:
		# Wait before each attack
		await get_tree().create_timer(attack_interval).timeout
		if !alive: break
		await perform_random_attack()


func perform_random_attack() -> void:
	# Disable all hitboxes before starting
	$SwipeHitbox.monitoring = false
	$HandfallHitbox.monitoring = false
	$HandfallHitbox/Slam1.disabled = true
	$HandfallHitbox/Slam2.disabled = true
	$HandfallHitbox/Slam3.disabled = true

	# Pick a new attack (not the same as last time if possible)
	var anims = ["handfall", "swipe"]
	var chosen_anim = anims.pick_random()
	if anims.size() > 1 and chosen_anim == last_attack:
		chosen_anim = anims.filter(func(a): return a != last_attack).pick_random()

	last_attack = chosen_anim

	if chosen_anim == "swipe":
		await do_swipe()
	elif chosen_anim == "handfall":
		await do_handfall()

	anim_sprite.play("idle")


# ----------------- INDIVIDUAL ATTACKS -----------------
func do_swipe() -> void:
	anim_sprite.play("swipe")
	await get_tree().create_timer(0.5).timeout # charge-up
	$SwipeHitbox.monitoring = true
	await anim_sprite.animation_finished
	$SwipeHitbox.monitoring = false

func do_handfall() -> void:
	$HandfallHitbox.monitoring = true
	anim_sprite.play("handfall")

	# First slam
	await get_tree().create_timer(1.2).timeout
	$HandfallHitbox/Slam1.disabled = false
	await get_tree().create_timer(0.1).timeout
	$HandfallHitbox/Slam1.disabled = true

	# Second slam
	await get_tree().create_timer(0.5).timeout
	$HandfallHitbox/Slam2.disabled = false
	await get_tree().create_timer(0.1).timeout
	$HandfallHitbox/Slam2.disabled = true

	# Third slam
	await get_tree().create_timer(0.8).timeout
	$HandfallHitbox/Slam3.disabled = false
	await get_tree().create_timer(0.1).timeout
	$HandfallHitbox/Slam3.disabled = true

	await anim_sprite.animation_finished
	$HandfallHitbox.monitoring = false

func do_shoot() -> void:
	if not projectile_scene:
		return

	var proj = projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)

	# get position of tree's marker2d
	var marker = $"../ProjectileMarker"
	proj.global_position = marker.global_position
	# Always shoot left
	proj.direction = Vector2.LEFT
	proj.speed = 250

	# Optional: if your projectile has a Sprite2D child, randomize its texture like Candy Queen
	if barrage_textures.size() > 0 and proj.has_node("Sprite2D"):
		proj.set_texture(barrage_textures.pick_random())

	await anim_sprite.animation_finished


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
	$CollisionShape2D.disabled = true
	Global.stage = 3
	Global.potency = 1
	Global.timer = 0
	get_tree().change_scene_to_file("res://Screens/Cutscene/Cutscene.tscn")


# ----------------- HITBOX SIGNALS -----------------
func _on_swipe_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(1)

func _on_handfall_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(1)
