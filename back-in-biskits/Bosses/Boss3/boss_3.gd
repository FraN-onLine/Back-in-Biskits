extends CharacterBody2D
class_name HotdoggierBoss

var boss_name = "Hotdoggier"
@export var max_hp: int = 670
var current_hp: int

@export var attack_interval: float = 4.0   # seconds between attacks
@export var damage_popup_scene: PackedScene

var player: Node2D = null
var alive: bool = true
var healthbar: Node
var last_attack: String = ""
var _laser_hit := false
var _smash_hit := false
var _tail_hit := false
var _enraged := false
var _smash_push_active := false

@export var attack_damage: int = 1
@export var enrage_health_ratio: float = 0.5   # 50% HP
@export var enrage_cooldown_reduction: float = 1.2  # seconds removed below 50% HP
@export var smash_knockback_strength: float = 240.0

signal boss_died

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var laser_area: Area2D = $LaserArea
@onready var smash_area: Area2D = $SmashArea
@onready var tail_area: Area2D = $TailArea
@onready var hurtbox: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("bosses")
	healthbar = $"../UI".get_node("Healthbar")
	healthbar.init_health(max_hp)
	current_hp = max_hp
	player = get_tree().get_first_node_in_group("player")

	laser_area.monitoring = false
	smash_area.monitoring = false
	tail_area.monitoring = false
	laser_area.body_entered.connect(_on_laser_area_body_entered)
	smash_area.body_entered.connect(_on_smash_area_body_entered)
	tail_area.body_entered.connect(_on_tail_area_body_entered)

	anim_sprite.play("idle")
	attack_loop()


func _process(_delta: float) -> void:
	if not alive:
		return

	# The hurtbox stays active during attacks (including the laser) so the
	# player's hits still connect; damage is only APPLIED while idle
	# (see take_damage), which makes the boss immune during laser/smash.
	hurtbox.disabled = false

	# Enable the matching danger area only during its active frame window
	var laser_window := false
	var smash_window := false
	var tail_window := false
	if anim_sprite.animation == "laser":
		laser_window = anim_sprite.frame >= 6 and anim_sprite.frame <= 7
	elif anim_sprite.animation == "smash":
		smash_window = anim_sprite.frame >= 8 and anim_sprite.frame <= 10
	elif anim_sprite.animation == "tail":
		tail_window = anim_sprite.frame >= 6 and anim_sprite.frame <= 8

	laser_area.monitoring = laser_window
	smash_area.monitoring = smash_window or _smash_push_active
	tail_area.monitoring = tail_window

	# Safety: damage once per attack even if the body was already overlapping
	if laser_window and not _laser_hit:
		if _is_player_overlapping(laser_area):
			_damage_player()
			_laser_hit = true
	if smash_window and not _smash_hit:
		if _is_player_overlapping(smash_area):
			_damage_player()
			_smash_hit = true
	if tail_window and not _tail_hit:
		if _is_player_overlapping(tail_area):
			_damage_player()
			_tail_hit = true


# ---------------- Attack loop ----------------
func attack_loop() -> void:
	while alive:
		await get_tree().create_timer(attack_interval).timeout
		if not alive:
			break
		await perform_random_attack()


func perform_random_attack() -> void:
	var attacks := ["laser", "smash", "tail"]
	var chosen = attacks.pick_random()
	if attacks.size() > 1 and chosen == last_attack:
		chosen = attacks.filter(func(a): return a != last_attack).pick_random()
	last_attack = chosen

	# Reset per-attack damage guards
	match chosen:
		"laser":
			_laser_hit = false
		"smash":
			_smash_hit = false
		"tail":
			_tail_hit = false

	anim_sprite.play(chosen)
	await anim_sprite.animation_finished
	if chosen == "smash":
		# Right when the smash lands, if the player is still inside the smash
		# zone, shove them away from the boss.
		_smash_pushaway()
	anim_sprite.play("idle")


# ---------------- Player damage ----------------
func _on_laser_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not _laser_hit:
		_laser_hit = true
		_damage_player()


func _on_smash_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not _smash_hit:
		_smash_hit = true
		_damage_player()


func _on_tail_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not _tail_hit:
		_tail_hit = true
		_damage_player()


# Keeps the smash zone collidable for a beat after the attack ends and pushes
# the player clear of it.
func _smash_pushaway() -> void:
	if not is_instance_valid(get_tree()):
		return
	_smash_push_active = true
	smash_area.monitoring = true
	await get_tree().process_frame
	var p = get_tree().get_first_node_in_group("player")
	if p and _is_player_overlapping(smash_area):
		var dir = (p.global_position - smash_area.global_position).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.UP
		if p.has_method("apply_knockback"):
			p.apply_knockback(dir * smash_knockback_strength)
		else:
			p.global_position += dir * 24.0
	_smash_push_active = false
	smash_area.monitoring = false


func _is_player_overlapping(area: Area2D) -> bool:
	for body in area.get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	return false


func _damage_player() -> void:
	var p = get_tree().get_first_node_in_group("player")
	if p and p.has_method("take_damage"):
		p.take_damage(attack_damage)


# ---------------- Damage taken ----------------
func take_damage(amount: int = 1) -> void:
	if not alive:
		return
	if anim_sprite.animation != "idle":
		return  # only hittable during idle

	current_hp -= amount
	current_hp = max(current_hp, 0)
	healthbar.set_health(current_hp)

	# Enrage at 50% HP: faster attacks (cooldown reduced by 1.2s, min 1.0s)
	if not _enraged and current_hp <= int(max_hp * enrage_health_ratio):
		_enraged = true
		attack_interval = maxf(attack_interval - enrage_cooldown_reduction, 1.0)

	if damage_popup_scene:
		var popup := damage_popup_scene.instantiate()
		get_tree().current_scene.add_child(popup)
		var jitter_x := randf_range(-6, 6)
		# Put the popup just above the boss's collision shape (hitbox), not at
		# the root position which sits below/away from the visible sprite.
		var popup_pos := hurtbox.global_position + Vector2(jitter_x, -20)
		if hurtbox.shape is RectangleShape2D:
			var rect := hurtbox.shape as RectangleShape2D
			popup_pos.y = hurtbox.global_position.y - rect.size.y * 0.5 - 8.0
		popup.show_damage(amount, popup_pos)

	anim_sprite.modulate = Color(1, 0.5, 0.5)  # flash red
	await get_tree().create_timer(0.1).timeout
	anim_sprite.modulate = Color(1, 1, 1)

	if not alive:
		return
	if current_hp <= 0:
		die()


func die() -> void:
	if not alive:
		return
	alive = false
	hurtbox.disabled = true
	laser_area.monitoring = false
	smash_area.monitoring = false
	tail_area.monitoring = false
	record_best_time(3)
	emit_signal("boss_died")
	Global.stage = 4
	Global.potency = 1
	Global.timer = 0
	Global.shield = 0
	get_tree().change_scene_to_file("res://Areas/hallway_4.tscn")


func record_best_time(stage: int) -> void:
	# Guard against the tree being torn down (e.g. a second die() racing a
	# scene change) which made get_tree() return null.
	if not is_instance_valid(get_tree()):
		return
	var ui_node = get_tree().get_first_node_in_group("ui")
	if ui_node and ui_node.has_method("get_stopwatch_time"):
		Global.submit_best_time(stage, ui_node.get_stopwatch_time())
