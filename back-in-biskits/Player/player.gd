extends CharacterBody2D
class_name Player

var PopupScene = preload("res://Pickup/Pickup UI/popup.tscn")

@export var speed: float = 200.0
@export var attack_cooldown: float = 0.6
@export var graham_bullet: PackedScene
@export var peanut_bullet: PackedScene
@export var shockwave_scene: PackedScene
@export var yoyoatk_scene: PackedScene
var can_attack: bool = true
var attack_cooldown_total := 0.0
var attack_cooldown_start_msec := 0

# Combo: consecutive hits landed without taking damage
var combo_count := 0
var combo_timer := 0.0
const COMBO_WINDOW := 2.0
var current_attack: String = "void"
var current_skill_icon
var cookie_potency = 1
var dead = false
var is_attacking = false
var dashing := false
var dash_velocity := Vector2.ZERO
var knockback_velocity := Vector2.ZERO
var _knockback_time := 0.0
const KNOCKBACK_DURATION := 0.1   # brief 0.1s push, applied once

# Screen shake (trauma-based, directional)
var shake_trauma := 0.0
var shake_direction := Vector2.ZERO
const SHAKE_DECAY := 2.4
const SHAKE_MAX_OFFSET := 14.0
@export var dash_speed := 280.0
@export var dash_distance := 150
@onready var smash_area = $SmashArea
@onready var smash_shape = $SmashArea/CollisionShape2D
var smash_pos


@onready var anim: AnimatedSprite2D = $Sprite2D # reference to sprite
@onready var swordanim = $AnimatedSprite2D
@onready var rushanim = $RushEffect
@onready var orb = $Orb

@onready var sword_sound = $AudioStreamPlayer
@onready var hammer_sound = $AudioStreamPlayer2
@onready var yoyo_sound = $AudioStreamPlayer3
@onready var shield_sound = $AudioStreamPlayer4
@onready var graham_sound = $AudioStreamPlayer5
@onready var rush_sound = $AudioStreamPlayer6

var hit_enemies: Array = [] #tracker

signal health_changed(new_hp: int)  # notify UI when HP updates
signal player_died


func _ready() -> void:
	smash_pos = smash_shape.position
	Global.lives = 5
	# Hard-safety: never inherit a stuck hit-stop/slow-mo from a previous scene
	Engine.time_scale = 1.0


func _process(delta: float) -> void:
	_update_camera_shake(delta)
	if dead or Global.dialog_open: return
	handle_movement(delta)

	# Combo meter decays when the player goes too long without landing a hit
	if combo_count > 0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo_count = 0
			combo_timer = 0.0

	if Input.is_action_just_pressed("attack") and can_attack:
		perform_attack()
		
	if current_attack == "lion_cracker":
		swordanim.visible = true
	else:
		swordanim.visible = false
		
	if Global.shield >= 1:
		$Shield.visible = true
		shield_sound.play()
	else:
		$Shield.visible = false
		
	if Global.lives <= 0:
		die()


# ---------------- Movement ----------------
func handle_movement(delta: float) -> void:
	if dead: return
	
	if dashing:
		# Move with dash
		var collision = move_and_collide(dash_velocity * delta)
		if collision:
			end_dash()
		return

	var input_dir = Vector2.ZERO
	input_dir.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir = input_dir.normalized()

	# Knockback (e.g. shoved by a boss attack): a brief 0.1s push that overrides
	# input once. move_and_slide() keeps it from passing through or sticking to
	# walls, and control is returned the moment the timer expires.
	if _knockback_time > 0.0:
		_knockback_time -= delta
		velocity = knockback_velocity
		move_and_slide()
		if _knockback_time <= 0.0:
			velocity = Vector2.ZERO
	else:
		velocity = input_dir * speed
		move_and_slide()

	

	# --- Animation handling ---
	if input_dir == Vector2.ZERO:
		# Idle
		if anim.animation != "idle" and is_attacking == false:
			anim.play("idle")
	else:
		# Walking
		if anim.animation != "walk" and is_attacking == false:
			anim.play("walk")

		# Flip horizontally if moving right
		if input_dir.x != 0:
			$Shield.flip_h = input_dir.x > 0
			rushanim.flip_h = input_dir.x > 0
			anim.flip_h = input_dir.x > 0
			swordanim.flip_h = input_dir.x > 0
			orb.flip_h = input_dir.x > 0
		var shape = $LionCrackerSword/CollisionShape2D
		var pos = shape.position
		pos.x = abs(pos.x) * (-1 if input_dir.x < 0 else 1)
		shape.position = pos
		var smash_area = $SmashArea
		var smash_shape = $SmashArea/CollisionShape2D
		smash_pos.x = abs(smash_pos.x) * (-1 if not anim.flip_h else 1)
		smash_shape.position = smash_pos


# Shove the player with an impulse (used by boss knockback etc.).
# The push is applied once and lasts KNOCKBACK_DURATION.
func apply_knockback(kb: Vector2) -> void:
	knockback_velocity = kb
	_knockback_time = KNOCKBACK_DURATION


# ---------------- Screen shake ----------------
func shake_camera(amount: float = 0.5, direction: Vector2 = Vector2.ZERO) -> void:
	shake_trauma = minf(shake_trauma + amount, 1.0)
	if direction.length() > 0.0:
		shake_direction = direction.normalized()


# Called by enemies whenever the player lands a hit on them.
func register_hit() -> void:
	combo_count += 1
	combo_timer = COMBO_WINDOW
	# Every 10-hit milestone: heal a bit of the hunger clock + tiny crunch
	if combo_count >= 10 and combo_count % 10 == 0:
		Global.timer = maxf(Global.timer - 2.0, 0.0)
		Global.hitstop(0.03)


# Fraction of the attack cooldown still remaining (0..1 window for the HUD).
func get_attack_cooldown_remaining() -> float:
	if can_attack or attack_cooldown_total <= 0.0:
		return 0.0
	return maxf(attack_cooldown_total - (Time.get_ticks_msec() - attack_cooldown_start_msec) / 1000.0, 0.0)


func _update_camera_shake(delta: float) -> void:
	var cam := get_node_or_null("Camera2D") as Camera2D
	if not cam:
		return
	if shake_trauma <= 0.0:
		cam.offset = Vector2.ZERO
		return
	shake_trauma = maxf(shake_trauma - SHAKE_DECAY * delta, 0.0)
	var strength := SHAKE_MAX_OFFSET * shake_trauma * shake_trauma
	if strength <= 0.01:
		cam.offset = Vector2.ZERO
		return
	var jitter := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	var dir := shake_direction
	if dir.length() < 0.01:
		dir = jitter
	cam.offset = dir * strength + jitter * strength * 0.45
# ---------------- Attacks ----------------
func perform_attack() -> void: #when mouse clicked read cookie type
	can_attack = false
	attack_cooldown_total = attack_cooldown
	attack_cooldown_start_msec = Time.get_ticks_msec()
#i pupush ko to w comments later btw
	match current_attack: #depends on what was picked up last
		"lion_cracker":
			sword_attack()
		"peanut_cookie":
			peanut_attack()
		"graham":
			graham_attack()
		"macaroon":
			yoyo_attack()
		"pistachio_cookie":
			hammer_attack()
		"oreo":
			oreo_rush()
		"biscoff_cookie":
			smash()

	await get_tree().create_timer(attack_cooldown).timeout #attack cooldown
	can_attack = true #so u can attack obv...




# ---------------- Damage & HP ----------------
func take_damage(amount: int = 1, from_dir: Vector2 = Vector2.ZERO) -> void:
	if Global.shield >= 1:
		Global.shield -= 1
		#make shield more transparent
		$Shield.modulate = Color(1, 1, 1, 0.3)
		await get_tree().create_timer(0.1).timeout
		$Shield.modulate = Color(1, 1, 1, 1)
		return
	# Directional screen-shake kick away from the attacker
	shake_camera(0.6, from_dir)
	$Sprite2D.modulate = Color(1, 0.5, 0.5)  # flash red
	await get_tree().create_timer(0.1).timeout
	$Sprite2D.modulate = Color(1, 1, 1)
	print("Player took damage! HP = %d" % Global.lives)
	Global.lives -= amount
	# Taking a hit breaks the combo
	combo_count = 0
	combo_timer = 0.0


func die() -> void:
	# Stash the current run time so the death screen can show it
	var ui_node = get_tree().get_first_node_in_group("ui")
	if ui_node and ui_node.has_method("get_stopwatch_time"):
		Global.last_death_time = ui_node.get_stopwatch_time()
	print("💀 Player died")
	emit_signal("player_died")
	anim.play("dead")
	dead = true
	$AnimatedSprite2D.visible = false
	await anim.animation_finished
	$Sprite2D.visible = false
	#wait 0.5 sec then go to title screen
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Screens/death_screen.tscn")


# -------------- Various Attacks ----------------

func smash() -> void:
	if is_attacking:
		return

	$SmashArea.reset_hits()

	is_attacking = true
	orb.play("disappear")
	speed = 140 #slow
	#hammer_sound.play()

	#6,7,8 damage per potency multiplied by Global.lives, so (6-30), (7-35), (8-40) each attack also has a 25% chance to reduce global potency by 1
	var base_damage := 6
	match cookie_potency:
		1:
			base_damage = 6
		2:
			base_damage = 7
		3:
			base_damage = 8
		_:
			base_damage = 1

	var total_damage = base_damage * (6 - Global.lives)

	smash_area.damage = total_damage
	smash_area.monitoring = false
	smash_shape.disabled = true

	anim.play("smash")

	#hits at 8 stops at 12
	while anim.animation == "smash":
		await anim.frame_changed

		if anim.frame == 8:
			smash_area.monitoring = true
			smash_shape.disabled = false
		elif anim.frame >= 12:
			smash_area.monitoring = false
			smash_shape.disabled = true
			break

	#25% chance to reduce global potency
	if randf() <= 0.25 and Global.potency > 0:
		Global.potency -= 1

	is_attacking = false
	speed = 200
	anim.play("idle")
	orb.play("idle")

	

func sword_attack() -> void:
	orb.play("disappear")
	$LionCrackerSword.damage = ((cookie_potency - 1) * 8) + 20

	hit_enemies.clear()  # reset hits for this swing
	var sword = $LionCrackerSword
	sword.monitoring = true
	sword.visible = true
	swordanim.play("attack")
	sword_sound.play()

	await swordanim.animation_finished

	sword.monitoring = false
	swordanim.play("default")
	orb.play("idle")
	
func peanut_attack() -> void:
	graham_sound.play()
	if not peanut_bullet: return
	var mouse_pos = get_global_mouse_position()
	var base_dir = (mouse_pos - global_position).normalized()
	var potency = cookie_potency

	match potency:
		1:
			_spawn_peanut(global_position, base_dir, 7.0)
		2:
			_spawn_peanut(global_position, base_dir, 6)
			await _stagger_peanut()
			_spawn_peanut(global_position, base_dir, 6)
		3:
			_spawn_peanut(global_position, base_dir, 5.0)
			await _stagger_peanut()
			_spawn_peanut(global_position, base_dir, 5.0)
			await _stagger_peanut()
			_spawn_peanut(global_position, base_dir, 5.0)
		_:
			_spawn_peanut(global_position, base_dir, 6.0)
			await _stagger_peanut()
			_spawn_peanut(global_position, base_dir, 6.0)

# 0.15s delay between extra peanut shots so multi-shots feel spaced, not
# fired all at once. Skips the wait if the player died or left the scene.
func _stagger_peanut() -> void:
	if not is_instance_valid(get_tree()) or is_queued_for_deletion():
		return
	await get_tree().create_timer(0.15).timeout

func _spawn_peanut(pos: Vector2, dir: Vector2, dmg: float) -> void:
	var b = peanut_bullet.instantiate()
	get_tree().current_scene.add_child(b)
	b.init(pos, dir, dmg, cookie_potency, self)

func graham_attack() -> void:
	graham_sound.play()
	if not graham_bullet: return
	#await is to wait for an event to finish, e.g. animation or timer
	var mouse_pos = get_global_mouse_position() #get where cursor was
	var base_dir = (mouse_pos - global_position).normalized()
	var potency = cookie_potency

	#potency is a word that means how strong something is
	#the longer you dont eat, the food becomes more potent
	#more powerful
	#too potent it will hurt you
	#eat -= 1 potency
	#bcuz u less hungry
	#yes thats potency, not hunger
	#potency is a term for medicine lols
	#because yknow if u take meds its more potent if u fuckin sck af and refuses to take shit from doctors
	#shoot based on potency
	match potency:
		#amt based on potency, 1 2 3 shots
		1:
			_spawn_graham(global_position, base_dir, 7.5)
		2:
			# front + 30 deg
			_spawn_graham(global_position, base_dir, 10)
			_spawn_graham(global_position, base_dir.rotated(deg_to_rad(30)), 12.5)
		_:
			# potency 3+
			_spawn_graham(global_position, base_dir, 12.5)
			_spawn_graham(global_position, base_dir.rotated(deg_to_rad(30)), 15.0)
			_spawn_graham(global_position, base_dir.rotated(deg_to_rad(-30)), 15.0)

func _spawn_graham(pos: Vector2, dir: Vector2, dmg: float) -> void:
	#yeah instance, this is the only scene that requires an external scene, bullets are independent of player
	var b = graham_bullet.instantiate() #make new copy of scene, BULLET
	get_tree().current_scene.add_child(b)
	b.init(pos, dir, dmg)
	#btw this is inefficient...
	
func hammer_attack() -> void:
	# slow down
	speed = 35
	is_attacking = true
	orb.play("disappear")
	anim.play("hammersmash")
	# Wait until animation hits the "slam" frame
	hammer_sound.play()
	await anim.animation_finished

	# Spawn shockwave at player position
	if shockwave_scene:
		var shock = shockwave_scene.instantiate()
		get_tree().current_scene.add_child(shock)
		shock.cookie_potency = cookie_potency
		shock.global_position = global_position

	# Restore movement
	is_attacking = false
	speed = 200
	anim.play("idle")
	orb.play("idle")

func yoyo_attack() -> void:
	if is_attacking:
		return
	
	is_attacking = true
	orb.play("disappear")
	anim.play("yoyoattack")
	
	if yoyoatk_scene:
		var yoyo_skill = yoyoatk_scene.instantiate()
		get_tree().current_scene.add_child(yoyo_skill)
		yoyo_skill.cookie_potency = cookie_potency
		yoyo_skill.global_position = global_position
	
	yoyo_sound.play()
	await anim.animation_finished
	
	is_attacking = false
	anim.play("idle")
	orb.play("idle")

func oreo_rush() -> void:
	if dashing or is_attacking: 
		rush_sound.play()
		return

	is_attacking = true
	dashing = true
	anim.play("idle")
	rushanim.visible = true
	rushanim.play("rush")
	orb.play("disappear")

	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - global_position).normalized()
	dash_velocity = dir * dash_speed
	anim.flip_h = dash_velocity.x > 0
	rushanim.flip_h = dash_velocity.x > 0
	orb.flip_h = dash_velocity.x > 0

	await anim.animation_finished
	if dashing: # only if not stopped by collision
		end_dash()

func end_dash() -> void:
	rushanim.visible = false
	dashing = false
	is_attacking = false
	velocity = Vector2.ZERO
	anim.play("idle")
	orb.play("idle")

	# Spawn shockwave
	if shockwave_scene:
		var shock = shockwave_scene.instantiate()
		get_tree().current_scene.add_child(shock)
		shock.oreoshockwave = true
		shock.cookie_potency = cookie_potency
		shock.global_position = global_position


# ---------------- Cookies Pickup ----------------
func pickup_cookie(cookie_type: String, atkcd, min_potency) -> void:
	if Global.potency == 0 or Global.potency < min_potency: 
		current_attack = "void"
		return
	if cookie_type == "cookie_cat":
		Global.shield = Global.potency - 1
		await get_tree().create_timer(0.1).timeout
		if Global.potency > 0:
			Global.potency -= 1
		return
	current_attack = cookie_type
	attack_cooldown = atkcd
	print("Picked up cookie! Attack changed to: %s: %d" % [cookie_type, cookie_potency])
	cookie_potency = Global.potency
	await get_tree().create_timer(0.1).timeout
	if Global.potency > 0:
		Global.potency -= 1

func show_cookie_pickup(display_name: String, icon_tex: Texture2D, min_potency) -> void:
	if Global.potency == 0:
		display_name = "Cookie Void"
		current_skill_icon = null
	elif Global.potency < min_potency:
		display_name = "Cookie Potent only at >=%d" % min_potency
		current_skill_icon = null
	else:
		if display_name != "Shield Active":
			current_skill_icon = icon_tex
		display_name = display_name + " %d" % ((Global.potency - ((min_potency if min_potency > 1 else 1)) + 1))
	
	var popup = PopupScene.instantiate()
	add_child(popup)  # attach popup to player so it follows them
	popup.setup(display_name, icon_tex)
	



#no, this one too, this is how i manage github + godot so well
