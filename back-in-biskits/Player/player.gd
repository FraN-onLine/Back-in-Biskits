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
var current_attack: String = "void"
var current_skill_icon
var cookie_potency = 1
var dead = false
var is_attacking = false
var dashing := false
var dash_velocity := Vector2.ZERO
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


func _process(delta: float) -> void:
	if dead: return
	handle_movement(delta)

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


# ---------------- Attacks ----------------
func perform_attack() -> void: #when mouse clicked read cookie type
	can_attack = false
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
func take_damage(amount: int = 1) -> void:
	if Global.shield >= 1:
		Global.shield -= 1
		#make shield more transparent
		$Shield.modulate = Color(1, 1, 1, 0.3)
		await get_tree().create_timer(0.1).timeout
		$Shield.modulate = Color(1, 1, 1, 1)
		return
	$Sprite2D.modulate = Color(1, 0.5, 0.5)  # flash red
	await get_tree().create_timer(0.1).timeout
	$Sprite2D.modulate = Color(1, 1, 1)
	print("Player took damage! HP = %d" % Global.lives)
	Global.lives -= amount


func die() -> void:
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
			_spawn_peanut(global_position, base_dir, 5.0)
		2:
			_spawn_peanut(global_position, base_dir, 7)
		_:
			_spawn_peanut(global_position, base_dir, 6.0)
			_spawn_peanut(global_position, base_dir, 6.0)

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
