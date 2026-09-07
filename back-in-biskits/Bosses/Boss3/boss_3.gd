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

@export var attack_damage: int = 1

signal boss_died

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var laser_area: Area2D = $LaserArea
@onready var smash_area: Area2D = $SmashArea
@onready var hurtbox: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("bosses")
	healthbar = $"../UI".get_node("Healthbar")
	healthbar.init_health(max_hp)
	current_hp = max_hp
	player = get_tree().get_first_node_in_group("player")

	laser_area.monitoring = false
	smash_area.monitoring = false
	laser_area.body_entered.connect(_on_laser_area_body_entered)
	smash_area.body_entered.connect(_on_smash_area_body_entered)

	anim_sprite.play("idle")
	attack_loop()


func _process(_delta: float) -> void:
	if not alive:
		return

	# Only hittable while playing the idle animation
	hurtbox.disabled = anim_sprite.animation != "idle"

	# Enable the matching danger area only during its active frame window
	var laser_window := false
	var smash_window := false
	if anim_sprite.animation == "laser":
		laser_window = anim_sprite.frame >= 6 and anim_sprite.frame <= 7
	elif anim_sprite.animation == "smash":
		smash_window = anim_sprite.frame >= 8 and anim_sprite.frame <= 10

	laser_area.monitoring = laser_window
	smash_area.monitoring = smash_window

	# Safety: damage once per attack even if the body was already overlapping
	if laser_window and not _laser_hit:
		if _is_player_overlapping(laser_area):
			_damage_player()
			_laser_hit = true
	if smash_window and not _smash_hit:
		if _is_player_overlapping(smash_area):
			_damage_player()
			_smash_hit = true


# ---------------- Attack loop ----------------
func attack_loop() -> void:
	while alive:
		await get_tree().create_timer(attack_interval).timeout
		if not alive:
			break
		await perform_random_attack()


func perform_random_attack() -> void:
	var attacks := ["laser", "smash"]
	var chosen = attacks.pick_random()
	if attacks.size() > 1 and chosen == last_attack:
		chosen = attacks.filter(func(a): return a != last_attack).pick_random()
	last_attack = chosen

	# Reset per-attack damage guards
	if chosen == "laser":
		_laser_hit = false
	else:
		_smash_hit = false

	anim_sprite.play(chosen)
	await anim_sprite.animation_finished
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

	if damage_popup_scene:
		var popup := damage_popup_scene.instantiate()
		get_tree().current_scene.add_child(popup)
		var jitter_x := randf_range(-6, 6)
		popup.show_damage(amount, global_position + Vector2(jitter_x, -20))

	anim_sprite.modulate = Color(1, 0.5, 0.5)  # flash red
	await get_tree().create_timer(0.1).timeout
	anim_sprite.modulate = Color(1, 1, 1)

	if current_hp <= 0:
		die()


func die() -> void:
	alive = false
	hurtbox.disabled = true
	laser_area.monitoring = false
	smash_area.monitoring = false
	record_best_time(3)
	emit_signal("boss_died")
	Global.stage = 4
	Global.potency = 1
	Global.timer = 0
	Global.shield = 0
	get_tree().change_scene_to_file("res://Areas/hallway_4.tscn")


func record_best_time(stage: int) -> void:
	var ui_node = get_tree().get_first_node_in_group("ui")
	if ui_node and ui_node.has_method("get_stopwatch_time"):
		Global.submit_best_time(stage, ui_node.get_stopwatch_time())
