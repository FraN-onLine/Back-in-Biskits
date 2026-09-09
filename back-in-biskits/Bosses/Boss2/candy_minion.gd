extends CharacterBody2D
class_name CandyMinion

@export var speed: float = 80
@export var max_hp: int = 50
@export var aoe_damage: int = 1
@export var aoe_radius: float = 40.0
@export var attack_interval: float = 3.5
@export var windup_time: float = 0.7      # telegraph window before the slam lands
@export var chase_range: float = 110.0    # start winding up when player inside this
@export var knockback_strength: float = 150.0
@export var damage_popup_scene: PackedScene

var hp: int
var player: Node2D = null
var alive := true

# State machine: spawning -> chasing -> winding -> attacking -> chasing
var _state := "spawning"
var _state_timer := 0.0
var _attack_timer := 0.0
var _attack_dealt := false

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var telegraph: Polygon2D = $Telegraph
@onready var spawn_sound = $spawm
@onready var atk_sound = $atk


func _ready() -> void:
	hp = max_hp
	player = get_tree().get_first_node_in_group("player")

	# AoE is an Area2D this time: it only hits the player while they are
	# physically inside it when the attack lands.
	attack_area.monitoring = false
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	telegraph.visible = false

	# Spawn animation: not hittable/chasing until it's fully on screen
	await _do_spawn()


# ---------------- State machine ----------------
func _physics_process(delta: float) -> void:
	if not alive or player == null:
		return

	match _state:
		"chasing":
			velocity = (player.global_position - global_position).normalized() * speed
			move_and_slide()
			# Start winding up only if the player is close enough AND cooldown is over
			_attack_timer -= delta
			if _attack_timer <= 0.0 and global_position.distance_to(player.global_position) <= chase_range:
				_begin_windup()
		"winding":
			# Keep chasing during the telegraph so the minion feels alive and
			# the danger zone (which follows it) stays fair/predictable.
			velocity = (player.global_position - global_position).normalized() * speed
			move_and_slide()
			_state_timer -= delta
			if _state_timer <= 0.0:
				_begin_attack()
		"attacking":
			velocity = (player.global_position - global_position).normalized() * speed
			move_and_slide()
			_state_timer -= delta
			if _state_timer <= 0.0:
				_end_attack()


# ---------------- Spawning ----------------
func _do_spawn() -> void:
	velocity = Vector2.ZERO
	spawn_sound.play()
	anim_sprite.play("spawn")
	await anim_sprite.animation_finished
	if not alive:
		return
	anim_sprite.play("idle")
	_state = "chasing"


# ---------------- Attack flow ----------------
func _begin_windup() -> void:
	_state = "winding"
	_state_timer = windup_time
	_attack_dealt = false
	anim_sprite.play("attack")
	atk_sound.play()
	# Show the danger zone + activate the Area2D detector
	telegraph.visible = true
	attack_area.monitoring = true


func _on_attack_area_body_entered(body: Node2D) -> void:
	# Player walked INTO the danger zone mid-telegraph - don't punish until the
	# actual slam (the overlap check in _begin_attack handles that).
	pass


func _begin_attack() -> void:
	_state = "attacking"
	_state_timer = 0.2  # short "impact" state so the slam reads visually
	# Damage anyone still standing inside the Area2D on impact
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			_damage_player()
			break


func _end_attack() -> void:
	_state = "chasing"
	_attack_timer = attack_interval
	anim_sprite.play("idle")
	telegraph.visible = false
	attack_area.monitoring = false


func _damage_player() -> void:
	if _attack_dealt or not player:
		return
	_attack_dealt = true
	var away := (player.global_position - global_position).normalized()
	if away == Vector2.ZERO:
		away = Vector2.UP
	if player.has_method("take_damage"):
		player.take_damage(aoe_damage, away)
	if player.has_method("apply_knockback"):
		player.apply_knockback(away * knockback_strength)


# ---------------- Damage taken ----------------
func take_damage(amount: int) -> void:
	if not alive:
		return
	Global.hitstop(0.04)
	hp -= amount
	_register_player_hit()

	if damage_popup_scene:
		var popup := damage_popup_scene.instantiate()
		get_tree().current_scene.add_child(popup)
		var jitter_x := randf_range(-6, 6)
		popup.show_damage(amount, global_position + Vector2(jitter_x, -20))

	anim_sprite.modulate = Color(1, 0.5, 0.5)  # flash red
	await get_tree().create_timer(0.2).timeout
	if is_instance_valid(anim_sprite):
		anim_sprite.modulate = Color(1, 1, 1)

	if hp <= 0:
		die()


func die() -> void:
	alive = false
	velocity = Vector2.ZERO
	telegraph.visible = false
	attack_area.monitoring = false
	queue_free()

func _register_player_hit() -> void:
	var p = get_tree().get_first_node_in_group("player")
	if p and p.has_method("register_hit"):
		p.register_hit()
