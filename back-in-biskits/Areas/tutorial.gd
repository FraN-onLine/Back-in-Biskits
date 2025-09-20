extends Node2D

@onready var skip = $UI/SkipButton
@onready var tutorial_label = $"UI/Tutorial Label"

# Tutorial progression
var current_step := -1  # -1 means free exploration phase
var steps = [
	{"desc": "Pick up a cookie to gain an attack (Atk = Left click)", "done": false},
	{"desc": "You have a potency bar below which accumalates overtime, Higher potency makes the attack you get stronger", "done": false},
	{"desc": "Remember to always keep watch of your potency", "done": false},
	{"desc": "Eating a cookie while you have 0 Potency nullifies your attacks", "done": false},
	{"desc": "On the other end, staying at max potency for too long will hurt you", "done": false},
	{"desc": "Control your hunger to effectively beat the stages", "done": false},
	{"desc": "Some cookies have a minimum potency to start being effective", "done": false}
]

# References to tutorial objects (set in editor)
@onready var cookie1 = $Cookie1
@onready var cookie2 = $Cookie2
@onready var cookie3 = $Cookie3
@onready var cookie4 = $Cookie4
@onready var dummy_enemy = $"Cake Dog"


func _ready() -> void:
	# Start with all tutorial objects hidden
	cookie1.visible = false
	cookie1.set_deferred("monitoring", false)
	cookie2.visible = false
	cookie2.set_deferred("monitoring", false)
	cookie3.visible = false
	cookie3.set_deferred("monitoring", false)
	cookie4.visible = false
	cookie4.set_deferred("monitoring", false)

	# Initial "explore" phase
	tutorial_label.text = ""
	await get_tree().create_timer(3.0).timeout
	next_step()  # begin step 0

func _physics_process(delta: float) -> void:
	if current_step == 3:
		Global.potency = 0
	if current_step == 6:
		Global.potency = 1

# ----------------- STEP LOGIC -----------------
func show_step() -> void:
	await get_tree().create_timer(0.3).timeout
	tutorial_label.text = steps[current_step]["desc"]

	match current_step:
		0:
			cookie1.visible = true
			cookie1.set_deferred("monitoring", true)

		1:
			await get_tree().create_timer(1.5).timeout
			cookie2.visible = true
			cookie2.set_deferred("monitoring", true)

		2: 
			await get_tree().create_timer(3.0).timeout
			next_step() 

		3: 
			Global.potency = 0
			cookie3.visible = true
			cookie3.set_deferred("monitoring", true)
			
		4: 
			Global.potency = 3
			Global.timer = 4
			await get_tree().create_timer(5).timeout
			next_step()
			
		5: 
			Global.potency = 1
			await get_tree().create_timer(3.0).timeout
			next_step() 
			
		6: 
			Global.potency = 1
			cookie4.visible = true
			cookie4.set_deferred("monitoring", true)


func mark_done() -> void:
	steps[current_step]["done"] = true
	next_step()


func next_step() -> void:
	current_step += 1
	if current_step < steps.size():
		show_step()
	else:
		finish_tutorial()


func finish_tutorial() -> void:
	tutorial_label.text = "Tutorial complete!"
	await get_tree().create_timer(2).timeout
	FadeManager.fade_out_then_change_scene("res://Areas/area_1.tscn")
	Global.stage = 1
	Global.potency = 1
	Global.timer = 0


# ----------------- SIGNAL HOOKS -----------------
# Cookie pickup
func _on_cookie_1_body_entered(body: Node2D) -> void:
	next_step()
	pass # Replace with function body.

func _on_cookie_2_body_entered(body: Node2D) -> void:
	next_step()
	pass # Replace with function body.


# Enemy death (hook from DummyEnemy die())
func _on_enemy_defeated():
	if current_step == 2:
		mark_done()


# ----------------- SKIP -----------------
func _on_skip_button_pressed():
	FadeManager.fade_out_then_change_scene("res://Areas/area_1.tscn")
	Global.stage = 1
	Global.potency = 1
	Global.timer = 0
